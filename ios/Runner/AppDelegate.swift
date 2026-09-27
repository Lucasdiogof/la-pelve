import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenPrivacy") {
      ScreenPrivacy.shared.register(with: registrar)
    }
  }
}

/// Proteção de telas com dado clínico, ligada pelo Dart
/// (SensitiveContentGuard) via canal "la_pelve/screen_privacy".
///
/// Enquanto ligada, cobre o conteúdo:
/// - quando o app perde o foco (a snapshot do app switcher sai coberta);
/// - enquanto a tela estiver sendo gravada ou espelhada.
/// O iOS não tem API para impedir screenshot; isso fica fora do alcance.
final class ScreenPrivacy: NSObject {
  static let shared = ScreenPrivacy()

  private var isProtected = false
  private var isInactive = false
  private var cover: UIView?

  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "la_pelve/screen_privacy",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setProtected" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.isProtected = (call.arguments as? Bool) ?? false
      self?.refresh()
      result(nil)
    }

    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(willResignActive),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(captureChanged),
      name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  @objc private func willResignActive() {
    isInactive = true
    refresh()
  }

  @objc private func didBecomeActive() {
    isInactive = false
    refresh()
  }

  @objc private func captureChanged() {
    refresh()
  }

  // Síncrono na main thread: no willResignActive a capa precisa estar na
  // tela ANTES de o iOS tirar a snapshot do app switcher.
  private func refresh() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { [weak self] in self?.refresh() }
      return
    }
    let shouldCover = isProtected && (isInactive || isScreenCaptured())
    if shouldCover { showCover() } else { hideCover() }
  }

  private func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func isScreenCaptured() -> Bool {
    keyWindow()?.windowScene?.screen.isCaptured ?? false
  }

  private func showCover() {
    guard cover == nil, let window = keyWindow() else { return }
    let view = UIView(frame: window.bounds)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.backgroundColor = .systemBackground
    window.addSubview(view)
    cover = view
  }

  private func hideCover() {
    cover?.removeFromSuperview()
    cover = nil
  }
}
