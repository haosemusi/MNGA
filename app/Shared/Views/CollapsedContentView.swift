//
//  CollapsedContentView.swift
//  NGA
//
//  Created by Bugen Zhao on 7/13/21.
//

import Foundation
import SwiftUI

struct CollapsedContentView<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  @State private var collapsedState: Bool = true
  @Environment(\.inSnapshot) private var inSnapshot

  // When in snapshot, we always show the content.
  var collapsed: Bool {
    inSnapshot ? false : collapsedState
  }

  var body: some View {
    VStack(alignment: .leading) {
      Button(action: { collapsedState.toggle() }) {
        HStack {
          collapseIcon
          Text(title)
            .animation(.none, value: collapsed) // disable animation to avoid glitch
        }.padding(.bottom, 1)
          .foregroundColor(.accentColor)
          .font(.subheadline.bold())
      }.buttonStyle(.plain)

      Group {
        if !collapsed {
          content()
        }
      }
    }.fixedSize(horizontal: false, vertical: true)
  }

  @ViewBuilder
  private var collapseIcon: some View {
    if #available(iOS 18.0, *) {
      Image(systemName: collapsed ? "chevron.down" : "chevron.up")
        .contentTransition(
          .symbolEffect(.replace.magic(fallback: .downUp)),
        )
    } else {
      Image(systemName: collapsed ? "chevron.down" : "chevron.up")
    }
  }
}

struct CollapsedContentView_Previews: PreviewProvider {
  static var previews: some View {
    List {
      ForEach(1 ... 10, id: \.self) { i in
        VStack(alignment: .leading) {
          Text(String(repeating: "Content \(i) ", count: 20))
          CollapsedContentView(title: "Title") {
            Text(String(repeating: "Collapsed \(i) ", count: 20))
          }
        }.fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
