//
//  CategoriesView.swift
//  IPTVee
//
//  Created by M1 on 11/2/21.
//

import SwiftUI
import iptvKit

struct CategoriesView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var searchText: String = ""
    @State var isActive: Bool = false
    @State var selectedItem: String?
    @State var toggleBackground: Bool = false
    @ObservedObject var plo = PlayerObservable.plo
    @ObservedObject var lgo = LoginObservable.shared
    @Environment(\.colorScheme) var colorScheme
    
    // This is our search filter
    var categorySearchResults: Categories {
        
        let main = cats
            .filter {
                "\($0.categoryName)".lowercased()
                    .contains(searchText.lowercased()) || searchText.isEmpty
            }
            .sorted {
                $0.categoryName.lowercased() < $1.categoryName.lowercased()
            }
        
        let usa = main
            .filter {$0.categoryName.lowercased().starts(with: "usa")}
        
        let en = main
            .filter {$0.categoryName.lowercased().starts(with: "en") }
        
        let uk = main
            .filter {$0.categoryName.lowercased().starts(with: "uk") }
        
        let other = main
            .filter {
                !$0.categoryName.lowercased().starts(with: "usa") &&
                !$0.categoryName.lowercased().starts(with: "uk") &&
                !$0.categoryName.lowercased().starts(with: "en")
            }
        
        return usa + en + uk + other
        
    }
    
    @State var isPortrait: Bool = false
    
    var body: some View {
        if !lgo.isLoggedIn {
            
            VStack {
                AboutScreenView()
                Button(action: {lgo.showingLogin = true}) {
                    Text("Login")
                }
                Spacer()
            }
            
        } else {
            NavigationView {
                Form {
                    ForEach(Array(categorySearchResults),id: \.categoryID) { cat in
                        NavigationLink(destination: ChannelsView(categoryID: cat.categoryID, categoryName: cat.categoryName)) {
                            HStack {
                                Text(cat.categoryName)
                            }
                            .foregroundColor(plo.previousCategoryID == cat.categoryID ? Color.white : Color.primary)
                            .padding(0)
                            .edgesIgnoringSafeArea([.all])
                        }
                        .isDetailLink(true)
                        .listRowSeparator(plo.previousCategoryID == cat.categoryID ? .hidden : .visible)
                        .listRowBackground(plo.previousCategoryID == cat.categoryID ? Color.accentColor : colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Categories")
                .disableAutocorrection(true)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("IPTVee")
                
                if isPad && isPortrait {
                    VStack {
                        
                        Spacer()
                        
                        Text("Press the back button for Categories and Channels.")
                        
                        Spacer()
                    }
                    .padding(.bottom, 45)
                }
    
            }
            .padding(.top, -10)
            
        }
    }
}

