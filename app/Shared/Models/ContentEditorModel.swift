//
//  ContentEditorModel.swift
//  MNGA
//
//  Created by Bugen Zhao on 2021/10/20.
//

import AlertToast
import Foundation
import SwiftUI
import SwiftUIX

class ContentEditorModel: ObservableObject {
  enum Panel {
    case sticker
    case none
  }

  private let keyboard = Keyboard.main

  @Published var showing = Panel.none {
    didSet { if showing != .none { keyboard.dismiss() } }
  }

  @Published var text: String
  @Published var selection: Range<Int>?

  @Published var image: Data? = nil
  @Published var showingImagePicker = false

  func showSticker() {
    showing = .sticker
  }

  init(initialText: String) {
    text = initialText
    selection = initialText.count ..< initialText.count
  }

  func insert(_ string: String) {
    let selection = resolvedSelection()
    let range = stringRange(for: selection)

    text.replaceSubrange(range, with: string)

    let insertionPoint = selection.lowerBound + string.count
    let textHash = text.hashValue

    // Sometimes it just doesn't work if we set string and selection at the same time...
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if self.text.hashValue == textHash { // text is not changed by other means
        self.selection = insertionPoint ..< insertionPoint
      }
    }
  }

  private func appendTag(_ tag: String, attribute: String? = nil) {
    let open = if let attribute {
      "[\(tag)=\(attribute)]"
    } else {
      "[\(tag)]"
    }
    let close = "[/\(tag)]"
    appendTag(open: open, close: close)
  }

  private func appendTag(open: String, close: String) {
    let selection = resolvedSelection()
    let range = stringRange(for: selection)
    let selectedText = String(text[range])
    text.replaceSubrange(range, with: open + selectedText + close)

    let insertionPoint = selection.upperBound + open.count
    let textHash = text.hashValue

    // Sometimes it just doesn't work if we set string and selection at the same time...
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if self.text.hashValue == textHash { // text is not changed by other means
        self.selection = insertionPoint ..< insertionPoint
      }
    }
  }

  private func resolvedSelection() -> Range<Int> {
    let end = text.count
    let selection = selection ?? end ..< end
    let lowerBound = min(max(selection.lowerBound, 0), end)
    let upperBound = min(max(selection.upperBound, lowerBound), end)
    return lowerBound ..< upperBound
  }

  private func stringRange(for selection: Range<Int>) -> Range<String.Index> {
    let lowerBound = text.index(text.startIndex, offsetBy: selection.lowerBound)
    let upperBound = text.index(text.startIndex, offsetBy: selection.upperBound)
    return lowerBound ..< upperBound
  }

  func appendBold() {
    appendTag("b")
  }

  func appendDel() {
    appendTag("del")
  }

  func appendCollapsed() {
    appendTag("collapse", attribute: "Collapsed Content".localized)
  }

  func appendQuoted() {
    appendTag("quote")
  }

  func appendAt() {
    appendTag(open: "[@", close: "]")
  }

  func insertSeparator() {
    insert("\n======\n")
  }

  func appendHeader() {
    appendTag(open: "===", close: "===")
  }

  func appendColor(_ color: String) {
    appendTag("color", attribute: color)
  }

  func appendSize(_ size: String) {
    appendTag("size", attribute: size)
  }

  func appendDice() {
    appendTag("dice")
  }

  func showImagePicker() {
    showingImagePicker = true
  }
}
