//
//  SettingsView.swift
//  lara
//
//  Created by ruter on 29.03.26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum method: String, CaseIterable {
    case vfs = "VFS"
    case sbx = "SBX"
    case hybrid = "Hybrid"
}

enum fmAppsDisplayMode: String, CaseIterable {
    case UUID = "UUID"
    case bundleID = "Bundle ID"
    case appName = "App Name"
}

enum logsdisplaymode: String, CaseIterable {
    case tabs = "In Tabs"
    case toolbar = "In Toolbar"
    case content = "Directly in ContentView"
}

struct SettingsView: View {
    @EnvironmentObject var mgr: laramgr
    
    @AppStorage("selectedMethod") private var selectedMethod: method = .hybrid
    @AppStorage("keepAlive") private var keepAlive: Bool = false
    @AppStorage("stashKRW") private var stashKRW: Bool = false
    
    @State private var downloadingKcache: Bool = false
    @State private var showKcacheImporter: Bool = false
    @State private var importingKcache: Bool = false
    @State private var showKcacheTips: Bool = false
    
    @AppStorage("logsdisplaymode") private var selectedLogsDisplayMode: logsdisplaymode = .toolbar
    @AppStorage("loggerNoBS") private var loggerNoBS: Bool = true
    
    @AppStorage("showFMInTabs") private var showFMInTabs: Bool = true
    @AppStorage("selectedFMAppsDisplayMode") private var selectedFMAppsDisplayMode: fmAppsDisplayMode = .appName
    @AppStorage("fmRecursiveSearch") private var fmRecursiveSearch: Bool = false
    
    @AppStorage("rcDockUnlimited") private var rcDockUnlimited: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: HeaderLabel(text: "About", icon: "info.circle")) {
                    AppInfoCell()
                    NavigationLink("Credits", destination: CreditsView())
                }
                
                Section(header: HeaderLabel(text: "Exploit", icon: "ant")) {
                    Picker("", selection: $selectedMethod) {
                        ForEach(method.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    NavigationLink("Modify Offsets", destination: OffsetManagementView())
                }
                
                // kernelcache
                Section(header: HeaderLabel(text: "Kernelcache", icon: "cpu"), footer: Text("Deleting and redownloading kernelcache may fix some issues. Try doing this before opening an issue on GitHub or asking for support in our [Discord](https://discord.gg/gw8PcRF3Jr) server.")) {
                    // download kcache
                    if !mgr.hasOffsets {
                        Button(action: {
                            guard !downloadingKcache else { return }
                            downloadingKcache = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                let ok = dlkerncache()
                                DispatchQueue.main.async {
                                    mgr.hasOffsets = ok
                                    downloadingKcache = false
                                }
                            }
                        }) {
                            if downloadingKcache {
                                LabeledContent("Downloading Kernelcache...") {
                                    ProgressView()
                                }
                            } else {
                                Text("Download Kernelcache")
                            }
                        }
                        .disabled(downloadingKcache)
                    }
                    
                    // import kcache
                    if !mgr.hasOffsets {
                        LabeledContent(content: {
                            Button(action: {
                                showKcacheTips.toggle()
                            }) {
                                Image(systemName: "info.circle")
                            }
                        }) {
                            Button("Import Kernelcache", action: {
                                guard !importingKcache else { return }
                                showKcacheImporter = true
                            })
                            .disabled(importingKcache)
                        }
                    }
                    
                    // delete kcache data
                    if mgr.hasOffsets {
                        Button("Remove Kernelcache", action: {
                            Alertinator.shared.alert(title: "Clear Kernelcache Data?", body: "This will delete all kernelcache data and remove saved offsets. You will have to redownload the data to use lara again.", actionLabel: "Confirm", action: {
                                clearKcacheData()
                            })
                        })
                    }
                }
                
                // tips
                if showKcacheTips {
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("How to obtain a kernelcache (macOS)")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text("1. Download the IPSW tool for your device.")
                            Link("https://github.com/blacktop/ipsw/releases",
                                 destination: URL(string: "https://github.com/blacktop/ipsw/releases")!)
                            
                            Text("2. Extract the archive.")
                            Text("3. Open Terminal.")
                            Text("4. Navigate to the extracted folder:")
                            Text("cd /path/to/ipsw_3.1.671_something_something/")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("5. Extract the kernel:")
                            Text("./ipsw extract --kernel [drag your ipsw here]")
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                            
                            Text("6. Get the kernelcache file.")
                            Text("7. Transfer the kernelcache to your iCloud or iPhone.")
                            Text("8. Tap the button above and select the kernelcache, for example kernelcache.release.iPhone14,3.")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: HeaderLabel(text: "App", icon: "gearshape"), footer: Text("If keep alive is enabled, the app will continue running even if it is minimized.")) {
                    Toggle("Keep Alive", isOn: $keepAlive)
                        .onChange(of: keepAlive) { _ in
                            if keepAlive {
                                if !kaenabled { toggleka() }
                            } else {
                                if kaenabled { toggleka() }
                            }
                        }
                    Toggle("Disable Log Dividers", isOn: $loggerNoBS)
                    Picker("Logs Display", selection: $selectedLogsDisplayMode) {
                        ForEach(logsdisplaymode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: HeaderLabel(text: "File Manager", icon: "folder"), footer: Text("Display Mode lets you change the way app folders get displayed in the file manager.")) {
                    Picker("Display Mode", selection: $selectedFMAppsDisplayMode) {
                        ForEach(fmAppsDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    Toggle("Recursive Search in File Manager", isOn: $fmRecursiveSearch)
                    Toggle("Show File Manager in Tabs", isOn: $showFMInTabs)
                }
                
                #if !DISABLE_REMOTECALL
                Section(header: HeaderLabel(text: "RemoteCall", icon: "syringe")) {
                    Toggle("Stash KRW primitives", isOn: $stashKRW)
                    Toggle("Allow >10 dock icons", isOn: $rcDockUnlimited)
                }
                #endif
            }
            .navigationTitle("Settings")
            .fileImporter(isPresented: $showKcacheImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importingKcache = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        var ok = false
                        let shouldStopAccess = url.startAccessingSecurityScopedResource()
                        defer {
                            if shouldStopAccess {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        let fm = FileManager.default
                        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let dest = docs.appendingPathComponent("kernelcache")
                            do {
                                if fm.fileExists(atPath: dest.path) {
                                    try fm.removeItem(at: dest)
                                }
                                try fm.copyItem(at: url, to: dest)
                                ok = dlkerncache()
                            } catch {
                                print("failed to import kernelcache: \(error)")
                                ok = false
                            }
                        }
                        DispatchQueue.main.async {
                            mgr.hasOffsets = ok
                            importingKcache = false
                        }
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    private func clearKcacheData() {
        let fm = FileManager.default
        
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_path")
        UserDefaults.standard.removeObject(forKey: "lara.kernelcache_size")
        
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let kernelcacheDocPath = docsPath.appendingPathComponent("kernelcache")
        
        do {
            if fm.fileExists(atPath: kernelcacheDocPath.path) {
                try fm.removeItem(at: kernelcacheDocPath)
                mgr.logmsg("Deleted kernelcache from Documents")
            }
        } catch {
            mgr.logmsg("Failed to delete kernelcache: \(error.localizedDescription)")
        }
        
        let tempPath = NSTemporaryDirectory()
        let tempFiles = ["kernelcache.release.ipad", "kernelcache.release.iphone", "kernelcache.release.ipad3", "kernelcache.release.iphone14,3"]
        
        for file in tempFiles {
            let path = tempPath + file
            do {
                if fm.fileExists(atPath: path) {
                    try fm.removeItem(atPath: path)
                    mgr.logmsg("Deleted temp kernelcache: \(file)")
                }
            } catch {
                mgr.logmsg("Failed to delete \(file): \(error.localizedDescription)")
            }
        }
        
        mgr.logmsg("Kernelcache data cleared")
        mgr.hasOffsets = false
    }
}
