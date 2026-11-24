import UIKit
import WebKit

/// Shows krillion.io in a web view that always ends at the top of the keyboard.
///
/// Why this fixes the layout: in Safari the keyboard covers the bottom of the
/// page, so the site slides the whole game up to keep the answer box visible,
/// which pushes the category and other players' answers off the top of the
/// screen. Here the web view itself shrinks to the space above the keyboard,
/// so the site sees a shorter screen and lays the full game out inside it.
final class GameViewController: UIViewController {
    static let startURL = URL(string: "https://krillion.io/party")!
    static let gameHost = "krillion.io"

    /// The site's background color, shown behind the status bar and while loading.
    private static let seaColor = UIColor(red: 5 / 255, green: 10 / 255, blue: 20 / 255, alpha: 1)

    private var webView: WKWebView!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.seaColor

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        // Report as mobile Safari, so the site and its bot check treat the app
        // like the browser it was built for.
        config.applicationNameForUserAgent = "Version/18.0 Mobile/15E148 Safari/604.1"
        config.userContentController.addUserScript(
            WKUserScript(source: Self.layoutFixScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = Self.seaColor
        webView.scrollView.backgroundColor = Self.seaColor
        // Keyboard and safe areas are handled by the constraints below, so stop
        // the scroll view from adding its own insets or shifting the page.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)

        // Leave the bottom safe area blank when the keyboard is closed, and
        // stop exactly at the keyboard's top edge when it is open.
        view.keyboardLayoutGuide.usesBottomSafeArea = true
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])

        // WebKit sometimes scrolls the page to "reveal" the focused box even
        // though it is already visible; undo that once the keyboard settles.
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidChange),
            name: UIResponder.keyboardDidShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidChange),
            name: UIResponder.keyboardDidHideNotification, object: nil
        )
        // Tell the page when a full keyboard is about to cover the screen, so
        // it can switch to the compact typing layout.
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification, object: nil
        )

        webView.load(URLRequest(url: Self.startURL))
    }

    @objc private func keyboardDidChange() {
        webView.evaluateJavaScript("window.__krillionApp && window.__krillionApp.settle()")
    }

    /// A hardware keyboard only shows a thin shortcut bar, which leaves plenty
    /// of room, so the compact layout only kicks in above this height.
    private static let fullKeyboardHeight: CGFloat = 150

    @objc private func keyboardWillChangeFrame(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboard = view.convert(frame, from: nil)
        let covered = max(0, view.bounds.maxY - keyboard.minY)
        // Only switch the compact layout ON here. Switching it off waits for
        // keyboardDidHide: the keyboard often hides and reappears in a blink
        // (e.g. focus moving between boxes), and turning it off early flashes
        // the banner ad over the answer box.
        if covered > Self.fullKeyboardHeight {
            setTyping(true)
        } else if covered > 0 {
            // A hardware keyboard's thin shortcut bar: normal layout.
            setTyping(false)
        }
    }

    @objc private func keyboardDidHide() {
        setTyping(false)
    }

    private func setTyping(_ typing: Bool) {
        webView.evaluateJavaScript("window.__krillionApp && window.__krillionApp.setTyping(\(typing))")
    }

    /// Injected into every krillion.io page. It only adds styling; it never
    /// reads or sends game data.
    private static let layoutFixScript = """
    (function () {
      var css = [
        /* The app already keeps the answer box above the keyboard, so turn off
           the site's own slide-up. It would only push the board off screen. */
        '.ds-root { translate: none !important; }',
        /* Stop the page bouncing or drifting while you type. */
        'html, body { overscroll-behavior: none; }',

        /* While the keyboard is open (the app adds .kr-app-typing to <html>):
           1. Shrink the category card to just the question, so the board
              keeps as much room as possible. */
        'html.kr-app-typing .ds-root .ds-card { padding: 6px 12px !important; }',
        'html.kr-app-typing .ds-root .ds-card .rnd,',
        'html.kr-app-typing .ds-root .ds-card .hint { display: none !important; }',
        'html.kr-app-typing .ds-root .ds-card .prompt {',
        '  font-size: 24px !important; line-height: 1.2 !important; margin: 0 !important;',
        '}',
        /* 2. Hide the bottom banner ad and give its space back to the game.
              visibility (not display) keeps the ad loaded, so it reappears
              as soon as the keyboard closes. */
        'html.kr-app-typing #fixed_container_bottom { visibility: hidden !important; }',
        'html.kr-app-typing, html.kr-app-typing * {',
        '  --kr-ad-bottom: 0px !important; --kr-ad-dock-lift: 0px !important;',
        '}',
        /* Puffer Party only:
           3. Hide the top bar (room code, players left, menu, leave, sound,
              chat) and move the category card to the very top. */
        'html.kr-app-typing .pf-root .ds-hud,',
        'html.kr-app-typing .pf-root .pf-leave,',
        'html.kr-app-typing .pf-root .ds-mute,',
        'html.kr-app-typing .pf-root .pf-chat-btn,',
        'html.kr-app-typing body:has(.pf-root) button[aria-controls="site-menu"] {',
        '  visibility: hidden !important; pointer-events: none !important;',
        '}',
        'html.kr-app-typing .pf-root .ds-card { top: 8px !important; }',
        /* 4. Shrink the players, their name plates and the puffer so seats
              stop overlapping in the shorter space. */
        'html.kr-app-typing .pf-root { --pf-spr: 46px !important; --pf-perch: 48px !important; }',
        'html.kr-app-typing .pf-root .pf-pbody { scale: 0.5; }',
        'html.kr-app-typing .pf-root .pf-plate { width: 56px !important; left: -28px !important; }',
        'html.kr-app-typing .pf-root .pf-name {',
        '  font-size: 12px !important; max-width: 100%; overflow: hidden; text-overflow: ellipsis;',
        '}',
        'html.kr-app-typing .pf-root .pf-heart { width: 8px !important; height: 7px !important; }',
        'html.kr-app-typing .pf-root .pf-meter { width: 24px !important; height: 4px !important; }'
      ].join('\\n');

      function addStyle() {
        if (document.getElementById('krillion-app-fix')) return;
        var style = document.createElement('style');
        style.id = 'krillion-app-fix';
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
      }

      window.__krillionApp = {
        setTyping: function (on) {
          document.documentElement.classList.toggle('kr-app-typing', !!on);
          // Let the site re-measure its layout for the new space.
          window.dispatchEvent(new Event('resize'));
        },
        settle: function () {
          // Game screens (Puffer Party and the daily game share the same
          // .ds-root layout) should never be scrolled.
          if (document.querySelector('.ds-root .ds-dock')) {
            window.scrollTo(0, 0);
          }
        }
      };

      addStyle();
      document.addEventListener('DOMContentLoaded', addStyle);
      window.visualViewport && window.visualViewport.addEventListener('resize', function () {
        window.__krillionApp.settle();
      });
    })();
    """
}

extension GameViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Links that leave Krillion (ads, Instagram, merch) open in Safari, so
        // tapping one never drops you out of a game.
        if action.targetFrame?.isMainFrame ?? false,
           action.navigationType == .linkActivated,
           let url = action.request.url,
           !Self.isKrillion(url) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // iOS can kill the page in the background; reload instead of going blank.
        webView.reload()
    }

    static func isKrillion(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return true }
        return host == gameHost || host.hasSuffix("." + gameHost)
    }
}

extension GameViewController: WKUIDelegate {
    /// Handles links that ask for a new window (target="_blank").
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for action: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = action.request.url {
            if Self.isKrillion(url) {
                webView.load(action.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        // WKWebView ignores the page's alert()/confirm() unless the app shows them.
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }
}
