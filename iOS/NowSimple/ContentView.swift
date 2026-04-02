//
//  ContentView.swift
//  NowSimple
//
//  Created by hanklee on 4/2/26.
//

import SwiftUI
import NowHybrid

struct ContentView: View {
    @StateObject private var model = HybridDemoViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NowHybrid iOS Demo")
                        .font(.title2.weight(.semibold))
                    Text("在线 URL、bundle 资源、sandbox 资源和 JS Bridge 都可以在这一页切换验证。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Source", selection: $model.selectedSource) {
                    ForEach(HybridDemoViewModel.Source.allCases) { source in
                        Text(source.title).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: model.selectedSource) { _, newValue in
                    model.load(newValue)
                }

                HStack(spacing: 12) {
                    Button("Reload") {
                        model.load(model.selectedSource)
                    }
                    Button("Back") {
                        model.goBack()
                    }
                    Spacer()
                    Text("Progress \(model.progress)%")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(model.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)

                WilmarHybridView(webView: model.webView)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    )
            }
            .padding(20)
            .navigationTitle("NowSimple")
        }
    }
}

#Preview {
    ContentView()
}
