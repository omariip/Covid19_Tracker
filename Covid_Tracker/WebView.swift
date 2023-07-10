//============================================================================
// WebView.swift
// =============
// SwiftUI wrapper for WKWebView
// It contains WebView struct for SwiftUI, and WebViewMessage to execute JS
// from WebView
//
// 1. How to initialize
// ====================
// WebView(url:URL?, message:WebViewMessage)
// - url: URL? to load
// - message: ObservableObject contains JavaScript code as String
//
// 2. How to execute JavaScript code from WebView
// ==============================================
// assign "js" variable with JavaScript code as String
// WebViewMessage.js = #"console.log("Hello")"#
//
// 3. How to receive message from JavaScript
// =========================================
// WebView has been configured a message handelr "handler1".
// Invoke window.webkit.messageHandlers.handler1.postMessage(msg) from JS
//
//  AUTHOR: Song Ho Ahn (song.ahn@gmail.com)
// CREATED: 2022-11-08
// UPDATED: 2022-11-10
//============================================================================

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable
{
    // properties
    var url: URL?
    @ObservedObject var message: WebViewMessage // to receive JS code
    var pageLoading = false

    // return instance of WKWebView
    func makeUIView(context: Context) -> WKWebView
    {
        // create WKWebView and config
        let webView = WKWebView()
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.navigationDelegate = context.coordinator // set delegate

        // set delegate for WKScriptMessageHandler
        // in JS, use window.webkit.messageHandlers.handler1.postMessage(msg)
        webView.configuration.userContentController.add(context.coordinator, name: "handler1")

        return webView
    }

    // update WKWebView
    func updateUIView(_ uiView: WKWebView, context: Context)
    {
        //print("updateeeeee")
        // if it is new JS code, execute it first
        if message.isNew
        {
            uiView.evaluateJavaScript(message.js)
            // reset the flag
            message.isNew = false
            return
        }

        // if URL is changed, load the URL
        guard let url = self.url else
        {
            print("URL is nil")
            return
        }

        // if URL begins with "file://", load it locally
        if url.isFileURL
        {
            uiView.loadFileURL(url, allowingReadAccessTo: url)
        }
        // otherwise, load it remotely
        else
        {
            let request = URLRequest(url:url)
            uiView.load(request)
        }
    }

    // create coordinator
    func makeCoordinator() -> WebViewCoordinator
    {
        return WebViewCoordinator(self)
    }

    // inline class for coordinator with WebKit delegates
    class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler
    {
        var webView: WebView

        init(_ webView: WebView)
        {
            self.webView = webView
        }

        // delegate functions for WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
        {
            // called when HTTP request is sent
            self.webView.pageLoading = true
            //print("WebView: Navigation started")
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!)
        {
            // called when webview starts receiving data from server
            //print("WebView: Start receiving page")
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
        {
            // called when webview completes receiving web page == DOMContentLoaded
            self.webView.pageLoading = false
            print("WebView: Page is loaded")
            webView.evaluateJavaScript(self.webView.message.js)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
        {
            // called when failed to load web page
            self.webView.pageLoading = false
            print("[ERROR] WebView : " + error.localizedDescription)
        }

        // delegate functions for WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
        {
            // called when it receives the message by postMessage() from JS
            if let dict = message.body as? [String:String]
            {
                dump(dict)
            }
        }
    }
}



// ViewModel to execute JavaScript code from WebView using evaluateJavaScript()
// publish "js" String with "isNew" Bool to WebView. Then, WebView will execute
// the "js" string if isNew == true in WebView.updateUIView()
class WebViewMessage: ObservableObject
{
    // publish the JS code with the flag
    var isNew = false
    var js: String = "" {
        willSet {
            isNew = true
            objectWillChange.send()
        }
    }
}
