//
//  WebImage.swift
//  Examples
//
//  Created by Gabriele de Simone on 11/19/26.
//

import FxCore
import WebKit
import Synchronization

/// A proof-of-concept for rendering content tied to `@MainActor`
///
/// - Note: This example shows one possible way to manage interaction between tasks that can only
///   complete on a specific actor/thread and your plug-in instance, which executes exclusively on a secondary thread.
///   Please note that is far from being the best way to render a snapshot of web pages to an image... it only accounts
///   for some of the errors you can bump into, and will often produce an image that looks incomplete, just because most
///   modern websites have evolved techniques to produce their final output over multiple passes (and this simple code
///   captures output on the very first such pass.)
///
@available(macOS 15, *)
class WebImagePlugIn : BasePlugIn, @unchecked Sendable {

    /// This plug-in uses `Mutex` in `Synchronization` and therefore cannot run pre-macOS 15.
    
    override class var availableMacOS: FxCoreVersion { FxCoreVersion(major: 15, minor: 0) }
    override class var identifier: String { "BE654277-60A3-4BC9-9FD1-F5A954B9E369" }
    override class var symbols: [String] { ["globe"] }
        
    @NSManaged var inputURL: String?
    @NSManaged var inputWidth: UInt
    @NSManaged var inputHeight: UInt
    @NSManaged var outputImage: FxCoreImage?
    
    override init() {
        super.init()
        add([[.key: #keyPath(inputURL), .type: FxCorePortType.string, .default: "https://fxfactory.com"],
             [.key: #keyPath(inputWidth), .type: FxCorePortType.unsignedInteger, .default: 1920, .sliderMin: 400, .sliderMax: 4000, .max: 10000],
             [.key: #keyPath(inputHeight), .type: FxCorePortType.unsignedInteger, .default: 1080, .sliderMin: 400, .sliderMax: 4000, .max: 10000],
             [.key: #keyPath(outputImage), .type: FxCorePortType.image]])
    }
        
    fileprivate let snapshot = Mutex<FxCoreImage?>(nil)
    fileprivate let delegate = Mutex<WebNavigationDelegate?>(nil)
    fileprivate let error = Mutex<any Error?>(nil)
    
    override func execute() throws {

        /// A pure "processor" node such as this can rely on FxCore to invoke its `execute` method
        /// only if one of its inputs has changed. This implementation goes a bit further in skipping
        /// the creation of a `WKWebView` if its previously allocated delegate already matches the
        /// fiven URL and web page dimensions.
        /// In a plug-in meant for production, you would likely implement far more sophisticated approaches,
        /// such as avoiding a whole new data request just for changing output size, and possibly by
        /// adopting other memoization techiques to minimize the amount of work done.
        
        guard let address = inputURL, !address.isEmpty,
              let url = URL(string: address),
              case let size = CGSize(width: CGFloat(inputWidth), height: CGFloat(inputHeight)),
                       size.width > 0, size.height > 0 else { throw error(.uncomputable) }
                
        if delegate.withLock({ $0 == nil || $0!.url != url || $0!.size != size }) {
            
            /// We always reset the error and any previously generate image when a new request is made.
            
            error.withLock { $0 = nil }
            snapshot.withLock { $0 = nil }
            
            Task { @MainActor in
                delegate.withLock { $0 = WebNavigationDelegate(plugIn: self, url: url, size: size) }
            }
        }
        
        /// If an error has been set by our delegate, it means the URL was wrong or some other connection
        /// problem occurred.
        
        if let error = error.withLock({ $0 }) {
            throw error
        }
        
        /// Any time we execute, we simply output the most recently-produced snapshot image.
        
        outputImage = snapshot.withLock { $0 }
        
    }
    
}

/// A separate class, required because `WKNavigationDelegate` and WebKit APIs are generally confined to
/// the main actor.
///
/// - Note: Note the use of `Mutex` in all completion handlers for thread-safe mutation of plug-in members.
///
@available(macOS 15, *)
@objc fileprivate class WebNavigationDelegate : NSObject, WKNavigationDelegate {
    
    private let plugIn: WebImagePlugIn
    private let webView: WKWebView
    let url: URL
    let size: CGSize
    
    init(plugIn: WebImagePlugIn, url: URL, size: CGSize) {
        self.plugIn = plugIn
        self.size = size
        self.url = url
        self.webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: WKWebViewConfiguration())
        super.init()
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        plugIn.error.withLock { $0 = error }
        plugIn.requestExecution()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        plugIn.error.withLock { $0 = error }
        plugIn.requestExecution()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.rect = CGRect(origin: .zero, size: webView.bounds.size)
        webView.takeSnapshot(with: snapshotConfig) { image, error in
            self.plugIn.error.withLock { $0 = error }
            self.plugIn.snapshot.withLock { $0 = image.flatMap { FxCoreImage(nsImage: $0) } }
            self.plugIn.requestExecution()
        }
    }
    
}
