//
//  AboutScreenView.swift
//  IPTVee
//
//  Created by M1 on 11/2/21.
//

import SwiftUI
import iptvKit

struct AboutScreenView: View {
    let image = "IPTVeeLogo"
    
    @ObservedObject var lgo = LoginObservable.shared
    
    var body: some View {
        Group {
            VStack {
                Text("IPTVee").fontWeight(.bold).font(.largeTitle).minimumScaleFactor(0.75).padding(.top, 50)
                HStack {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230.0, height: 230)
                        .background(Color.clear)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 48)
                        .stroke(Color.primary, lineWidth: 3)
                )
                
                Text("IPTVee (c) 2021 Todd Bruss").font(.callout).minimumScaleFactor(0.75).padding(.top, 10)
                    .padding(.bottom, 25)
            }
        }
        .statusBar(hidden: isPad)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {lgo.isLoggedIn = false; lgo.showingLogin = true}) {
                    Text("Login")
                }
            }
        }
    }
}
