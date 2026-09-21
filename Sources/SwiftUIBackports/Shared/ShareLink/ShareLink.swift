import SwiftBackports

#if os(macOS) || os(iOS)
import SwiftUI
#if canImport(LinkPresentation)
import LinkPresentation
#endif

@available(iOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
@available(tvOS, unavailable)
public extension Backport where Wrapped == Any {
    struct ShareLink<Data, PreviewImage, PreviewIcon, Label>: View where Data: RandomAccessCollection, Data.Element: Shareable, Label: View {
        @State private var activity: ActivityItem<Data>?

        let label: Label
        let data: Data
        let subject: String?
        let message: String?
        let preview: (Data.Element) -> SharePreview<PreviewImage, PreviewIcon>

        // Xcode 27 / Swift 6.4 工具链存在编译器缺陷（swiftlang/swift#91700）：
        // 当带默认值的存储属性（此处为 @State activity 的 backing 存储 _activity）的默认值初始化表达式
        // 仅被位于其它文件的便利 init 引用时，该符号不会被 emit，导致链接报
        // "Undefined symbols: variable initialization expression of ...ShareLink.(__activity)"。
        // 解决方案：提供本 designated init 显式初始化 _activity，并让所有便利 init 完全委托到 self.init(...)，
        // 委托后便利 init 不再引用默认值符号，从而绕过该缺陷。
        init(label: Label, data: Data, subject: String?, message: String?, preview: @escaping (Data.Element) -> SharePreview<PreviewImage, PreviewIcon>) {
            self._activity = State(wrappedValue: nil)
            self.label = label
            self.data = data
            self.subject = subject
            self.message = message
            self.preview = preview
        }

        public var body: some View {
            Button {
                activity = ActivityItem(data: data)
            } label: {
                label
            }
            .shareSheet(item: $activity)
        }
    }
}

//final class TransferableActivityProvider<Data: Shareable, Image: View, Icon: View>: UIActivityItemProvider {
//    let title: String?
//    let subject: String?
//    let message: String?
//    let image: Image?
//    let icon: Icon?
//    let data: Data
//
//    init(data: Data, title: String?, subject: String?, message: String?, image: Image?, icon: Icon?) {
//        self.title = title
//        self.subject = subject
//        self.message = message
//        self.image = image
//        self.icon = icon
//        self.data = data
//
//        let url = URL(fileURLWithPath: NSTemporaryDirectory())
//            .appendingPathComponent("tmp")
//            .appendingPathExtension(data.pathExtension)
//
//        super.init(placeholderItem: url)
//    }
//
//    override var item: Any {
//        data.itemProvider as Any
//    }
//
//    override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
//        let metadata = LPLinkMetadata()
//        metadata.title = title
////        let icon = ImageRenderer(content: activity.icon)
////        metadata.iconProvider = NSItemProvider(object: UIImage())
////        metadata.imageProvider = NSItemProvider(object: UIImage())
//        return metadata
//    }
//
//    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String { subject ?? "" }
//
//}
#endif
