import SwiftUI
import SwiftBackports

#if os(iOS)
public extension Backport where Wrapped: View {
    func focused<Value>(_ binding: Binding<Value?>, equals value: Value) -> some View where Value: Hashable {
        wrapped.modifier(FocusModifier(focused: binding, value: value))
    }
}

private struct FocusModifier<Value: Hashable>: ViewModifier {
    @Environment(\.backportSubmit) private var submit
    @Backport.StateObject private var coordinator = Coordinator()
    @Binding var focused: Value?
    var value: Value

    func body(content: Content) -> some View {
        content
            // this ensures when the field goes out of view, it doesn't retain focus
            .onWillDisappear { focused = nil }
            .sibling(forType: UITextField.self) { proxy in
                let view = proxy.instance
                coordinator.observe(field: .textField(view))

                coordinator.onBegin = {
                    focused = value
                }

                coordinator.onReturn = {
                    submit()
                }

                coordinator.onEnd = {
                    guard focused == value else { return }
                    focused = nil
                }

                if focused == value, view.isUserInteractionEnabled, view.isEnabled {
                    view.becomeFirstResponder()
                }
            }
            .sibling(forType: UITextView.self, body: { proxy in
                let view = proxy.instance
                coordinator.observe(field: .textView(view))

                coordinator.onBegin = {
                    focused = value
                }

                coordinator.onReturn = {
                    submit()
                }

                coordinator.onEnd = {
                    guard focused == value else { return }
                    focused = nil
                }

                if focused == value, view.isUserInteractionEnabled, view.isEditable {
                    view.becomeFirstResponder()
                }
            })
            .backport.onChange(of: focused) { newValue in
                if newValue == nil {
                    coordinator.resignFirstResponder()
                }
            }
    }
}

private enum CoordinatorEnum {
    case textField(UITextField)
    case textView(UITextView)
}

private class Coordinator: NSObject, ObservableObject {
    private var object:CoordinatorEnum?
    private weak var textFieldDelegate:UITextFieldDelegate?
    private weak var textViewDelegate:UITextViewDelegate?

    var onBegin: () -> Void = { }
    var onReturn: () -> Void = { }
    var onEnd: () -> Void = { }

    override init() { }

    func observe(field: CoordinatorEnum) {
        object = field
        
        switch field {
        case .textField(let field):
            if field.delegate !== self && textFieldDelegate == nil {
                textFieldDelegate = field.delegate
                field.delegate = self
            }
        case .textView(let field):
            if field.delegate !== self && textViewDelegate == nil {
                textViewDelegate = field.delegate
                field.delegate = self
            }
        }
    }
    
    func resignFirstResponder() {
        switch object {
        case .textField(let field):
            field.resignFirstResponder()
        case .textView(let field):
            field.resignFirstResponder()
        case nil:
            break
        }
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        switch object {
        case .textField:
            if textFieldDelegate?.responds(to: aSelector) ?? false { return true }
        case .textView:
            if textViewDelegate?.responds(to: aSelector) ?? false { return true }
        case nil:
            break
        }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) { return self }
        switch object {
        case .textField:
            return textFieldDelegate
        case .textView:
            return textViewDelegate
        default:
            return nil
        }
    }
}

extension Coordinator: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldDelegate?.textFieldDidBeginEditing?(textField)
        onBegin()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldDelegate?.textFieldDidEndEditing?(textField)
        onEnd()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn()
        // prevent auto-resign
        return false
    }
}

extension Coordinator: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidBeginEditing?(textView)
        onBegin()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidEndEditing?(textView)
        onEnd()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.returnKeyType != .default,text == "\n" {
            onReturn()
            return false
        }
        return textViewDelegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }
}

private struct WillDisappearHandler: UIViewControllerRepresentable {

    let onWillDisappear: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ViewWillDisappearViewController(onWillDisappear: onWillDisappear)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private class ViewWillDisappearViewController: UIViewController {
        let onWillDisappear: () -> Void

        init(onWillDisappear: @escaping () -> Void) {
            self.onWillDisappear = onWillDisappear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            onWillDisappear()
        }
    }
}

private extension View {
    func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
        background(WillDisappearHandler(onWillDisappear: perform))
    }
}
#endif
