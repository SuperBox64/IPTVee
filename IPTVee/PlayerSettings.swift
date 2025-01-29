//
//  CategoriesView.swift
//  IPTVee
//
//  Created by Todd Bruss on 9/28/21.
//

import SwiftUI
import iptvKit

struct PlayerSettings: View {
    @ObservedObject var settings = SettingsObservable.shared
    
    var body: some View {
        GeometryReader { geometry in
            
            List {
                Section(header: Text("Device")) {
                    Toggle("Xtreme HLS", isOn: $settings.deviceHLSXtrem)
                    Toggle("Apple HLS", isOn: $settings.deviceHLSApple)
                }
                
                Section(header: Text("AirPlay")) {
                    Toggle("Apple Branded", isOn: $settings.airplayAppleBranded)
                    Toggle("Third Party", isOn: $settings.airplayThirdParty)
                }
                
                Section(header: Text("Autoplay")) {
                    Toggle("Play on Channel Select", isOn: $settings.autoPlayOnSelect)
                    Toggle("Stop when exiting Player View", isOn: $settings.stopWhenExitingPlayer)
                    Toggle("Background Playback", isOn: $settings.backgroundPlayback)
                }
                .toggleStyle(.switch)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("Player Settings")
            }
            .onAppear {
                readPlayerSettings()
            }
            .onDisappear{
                savePlayerSettings()
            }
        }
    }
}
