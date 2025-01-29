//
//  ContentView.swift
//  IPTVee
//
//  Created by Todd Bruss on 9/27/21.
//

import SwiftUI
import iptvKit
import AVFoundation

struct LoginSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var obs = LoginObservable.shared
    @State var userName: String = LoginObservable.shared.config?.userInfo.username ?? ""
    @State var passWord: String = LoginObservable.shared.config?.userInfo.password ?? ""
    @State var service: String = LoginObservable.shared.config?.serverInfo.url ?? "ky-iptv.com"
    @State var https: Bool = false
    @State var port: String = LoginObservable.shared.config?.serverInfo.port ?? "80"
    @State var title: String = "IPTVee"
    @State var channelCacheText: String = "Channel Cache"
    
    var body: some View {
      
        NavigationView {
            List {
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $userName)
                    SecureField("Password", text: $passWord)

                    TextField("iptvService.tv", text: $service)
                    TextField("port #", text: $port)
                        .keyboardType(.numberPad)
                    Button(action: localLogin) {
                        Text("Login")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(obs.isLoginButtonDisabled)
                }
                
                Section(header: Text("Status")) {
                    Text(obs.status)
                        .font(.body)
                        .fontWeight(.regular)
                        .frame(maxWidth: .infinity, alignment: .center)
                    obs.isLoginButtonDisabled ? AnyView(ProgressView().frame(maxWidth: .infinity, alignment: .center)) : AnyView(EmptyView())
                }
                
                Button("Done") {
                    obs.isLoggedIn = true
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!obs.isLoggedIn)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Section(header: Text("Need IPTV Access?")) {
                    if let url = URL(string: "https://xtremehdiptv.org/billing/aff.php?aff=251") {
                        Link("Get Xtreme HD IPTV", destination: url)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section(header: Text(channelCacheText)) {
                    Button(action: clearChannelCache) {
                        Text("Clear Channel Cache")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("IPTVee Login")
            .toolbar {
                Button(action: {obs.showingLogin = false}) {
                        Text("Done")
                }.frame(alignment: .topTrailing)
            }
        } 
    }
    
    func localLogin() {
        DispatchQueue.global().async {
            if !userName.isEmpty && !passWord.isEmpty && !service.isEmpty && !port.isEmpty {
                login(userName, passWord, service, port)
            }
        }
    }
    
    func clearChannelCache() {
        let resetCache = Data()
        let file = getDocumentsDirectory().appendingPathComponent("channels.dat")
        try? resetCache.write(to: file)
        
        channelCacheText = "Channel Cache Cleared"
    }
}

func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
}
