//
//  ContentTextEditorView.swift
//  ContentTextEditorView
//
//  Created by Bugen Zhao on 8/26/21.
//

import Foundation
import SwiftUI
import SwiftUIIntrospect
import UIKit

struct ContentTextEditorView: View {
  @ObservedObject var model: ContentEditorModel
  @StateObject private var legacySelectionObserver = LegacyTextSelectionObserver()

  @Binding var focused: Bool

  @ViewBuilder
  var colorMenu: some View {
    ForEach(ContentCombiner.palette.elements, id: \.key) { element in
      let name = element.key
      let color = element.value

      Button(action: { performEditorAction { model.appendColor(name) } }) {
        Label(name, systemImage: "circle.fill")
          .tint(color)
      }
    }
  }

  @ViewBuilder
  var fontSizeMenu: some View {
    let smallSizes = ["10%", "50%", "80%", "90%"]
    let largeSizes = ["110%", "120%", "150%", "200%"]

    Section {
      ForEach(smallSizes, id: \.self) { size in
        Button(action: { performEditorAction { model.appendSize(size) } }) {
          Label(size, systemImage: "textformat.size.smaller")
        }
      }
    }

    Section {
      ForEach(largeSizes, id: \.self) { size in
        Button(action: { performEditorAction { model.appendSize(size) } }) {
          Label(size, systemImage: "textformat.size.larger")
        }
      }
    }
  }

  @ViewBuilder
  private var editor: some View {
    if #available(iOS 18.0, *) {
      TextEditor(text: $model.text, selection: nativeSelection)
    } else {
      TextEditor(text: $model.text)
        .introspect(.textEditor, on: .iOS(.v17)) { textView in
          legacySelectionObserver.observe(textView, model: model)
        }
        .onChange(of: model.selection) { legacySelectionObserver.applySelection($1, in: model.text) }
    }
  }

  @available(iOS 18.0, *)
  private var nativeSelection: Binding<TextSelection?> {
    Binding(
      get: {
        guard let selection = model.selection else { return nil }
        let end = model.text.count
        let lowerOffset = min(max(selection.lowerBound, 0), end)
        let upperOffset = min(max(selection.upperBound, lowerOffset), end)
        let lowerBound = model.text.index(model.text.startIndex, offsetBy: lowerOffset)
        let upperBound = model.text.index(model.text.startIndex, offsetBy: upperOffset)
        return TextSelection(range: lowerBound ..< upperBound)
      },
      set: { selection in
        guard let selection, case let .selection(range) = selection.indices else {
          model.selection = nil
          return
        }
        let lowerBound = model.text.distance(from: model.text.startIndex, to: range.lowerBound)
        let upperBound = model.text.distance(from: model.text.startIndex, to: range.upperBound)
        model.selection = lowerBound ..< upperBound
      },
    )
  }

  private func performEditorAction(_ action: () -> Void) {
    if #unavailable(iOS 18.0) {
      legacySelectionObserver.synchronizeSelection()
    }
    action()
  }

  var body: some View {
    editor
      .toolbar {
        // Show toolbar only when focused, otherwise it will also be shown in other text fields.
        if focused {
          ToolbarItemGroup(placement: .keyboard) {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 20) {
                Button(action: { performEditorAction(model.showSticker) }) {
                  Image(systemName: "face.smiling")
                }
                Button(action: { performEditorAction(model.showImagePicker) }) {
                  Image(systemName: "photo")
                }
                Button(action: { performEditorAction(model.appendBold) }) {
                  Image(systemName: "bold")
                }
                Button(action: { performEditorAction(model.appendDel) }) {
                  Image(systemName: "strikethrough")
                }
                Menu { colorMenu } label: {
                  Image(systemName: "paintpalette")
                }
                Menu { fontSizeMenu } label: {
                  Image(systemName: "textformat.size")
                }
                Button(action: { performEditorAction(model.appendCollapsed) }) {
                  Image(systemName: "chevron.up.chevron.down")
                }
                Button(action: { performEditorAction(model.appendAt) }) {
                  Image(systemName: "at")
                }
                Button(action: { performEditorAction(model.appendQuoted) }) {
                  Image(systemName: "quote.bubble")
                }
                Button(action: { performEditorAction(model.appendDice) }) {
                  Image(systemName: "dice")
                }
                Button(action: { performEditorAction(model.insertSeparator) }) {
                  Image(systemName: "minus")
                }
                Button(action: { performEditorAction(model.appendHeader) }) {
                  Image(systemName: "h.square")
                }
              }
              .padding(.horizontal)
            }.scrollTargetBehavior(.paging)

            Spacer()

            Button(action: hideKeyboard) {
              Image(systemName: "keyboard.chevron.compact.down")
            }
          }
        }
      }
  }

  private func hideKeyboard() {
    withAnimation {
      focused = false
    }
  }
}

@MainActor
private final class LegacyTextSelectionObserver: ObservableObject {
  private weak var textView: UITextView?
  private weak var model: ContentEditorModel?

  func observe(_ textView: UITextView, model: ContentEditorModel) {
    guard self.textView !== textView else { return }
    self.textView = textView
    self.model = model
    synchronizeSelection()
  }

  func applySelection(_ selection: Range<Int>?, in text: String) {
    guard let textView, let selection else { return }
    let end = text.count
    let lowerOffset = min(max(selection.lowerBound, 0), end)
    let upperOffset = min(max(selection.upperBound, lowerOffset), end)
    let lowerBound = text.index(text.startIndex, offsetBy: lowerOffset)
    let upperBound = text.index(text.startIndex, offsetBy: upperOffset)
    let selectedRange = NSRange(lowerBound ..< upperBound, in: text)
    if textView.selectedRange != selectedRange {
      textView.selectedRange = selectedRange
    }
  }

  func synchronizeSelection() {
    guard let textView, let model,
          let range = Range(textView.selectedRange, in: textView.text)
    else { return }

    let lowerBound = textView.text.distance(from: textView.text.startIndex, to: range.lowerBound)
    let upperBound = textView.text.distance(from: textView.text.startIndex, to: range.upperBound)
    let selection = lowerBound ..< upperBound
    if model.selection != selection {
      model.selection = selection
    }
  }
}

// MARK: - Preview

struct ContentTextEditorView_Previews: PreviewProvider {
  static var previews: some View {
    ContentTextEditorView(model: ContentEditorModel(initialText: "Sample text"), focused: .constant(true))
  }
}
