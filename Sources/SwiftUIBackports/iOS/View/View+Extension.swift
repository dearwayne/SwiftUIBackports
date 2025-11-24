//
//  File.swift
//  SwiftUIBackports
//
//  Created by wayne on 2025/11/21.
//
import SwiftUI
import SwiftBackports

#if os(iOS)
@available(iOS, deprecated: 15)
public extension Backport where Wrapped: View {
    /// 隐藏List的线条
    ///
    /// /// - Parameters:
    ///   - visibility: 是否可见，iOS 15之前，.automatic 不处理，返回原视图
    ///   - background: row的背景色，iOS 14下必须使用不透明的颜色覆盖线条，达到隐藏线条的目的，其他的版本需要自己调background方法，设置row的背景色
    @ViewBuilder
    func listRowSeparator<Background>(_ visibility: Backport<Any>.Visibility,_ background: Background) -> some View where Background : View {
        if #available(iOS 15.0, *) {
            switch visibility {
            case .automatic:
                wrapped.listRowSeparator(.automatic)
            case .visible:
                wrapped.listRowSeparator(.visible)
            case .hidden:
                wrapped.listRowSeparator(.hidden)
            }
        } else if #available(iOS 14.0, *) {
            switch visibility {
            case .automatic:
                wrapped
            case .visible:
                wrapped.frame(maxWidth: nil, maxHeight: nil)
                    .listRowInsets(.none)
                    .background(background)
            case .hidden:
                wrapped.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
                    .background(background)
            }
        } else {
            wrapped.onAppear {
                switch visibility {
                case .automatic:
                    break
                case .visible:
                    UITableView.appearance().separatorStyle = .singleLine
                case .hidden:
                    UITableView.appearance().separatorStyle = .none
                }
            }
            .onDisappear {
                switch visibility {
                case .automatic:
                    break
                case .visible:
                    break
                case .hidden:
                    UITableView.appearance().separatorStyle = .singleLine
                }
            }
        }
    }
}

#endif
