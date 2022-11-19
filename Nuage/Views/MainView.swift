//
//  MainView.swift
//  Nuage
//
//  Created by Laurin Brandner on 26.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import SwiftUI
import Combine
import AppKit
import URLImage
import Introspect
import SoundCloud

private enum NavigationDetail {
    case stream
    case likes
    case history
    case following
    case playlist(String, String)
    
    var title: String {
        switch self {
        case .stream: return "Stream"
        case .likes: return "Likes"
        case .history: return "History"
        case .following: return "Following"
        case let .playlist(name, _): return name
        }
    }
    
    var imageName: String? {
        switch self {
        case .stream: return "bolt.horizontal.fill"
        case .likes: return "heart.fill"
        case .history: return "clock.fill"
        case .following: return "person.2.fill"
        case .playlist(_, _): return nil
        }
    }
    
}

extension NavigationDetail: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title.hashValue)
        if case .playlist(_, let id) = self {
            hasher.combine(id.hashValue)
        }
    }
    
}

extension NavigationDetail: Identifiable {
    
    var id: String {
        if case .playlist(_, let id) = self {
            return id
        }
        return title
    }
    
}

struct MainView: View {
    
    @State private var navigationSelection: NavigationDetail = .stream
    @State private var playlists = [Playlist]()
    @State private var searchQuery = ""
    @State private var presentProfile = false
    @State private var subscriptions = Set<AnyCancellable>()
    
    @EnvironmentObject private var commands: Commands
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $navigationSelection) {
                    sidebarMenu(for: .stream)
                    sidebarMenu(for: .likes)
                    sidebarMenu(for: .history)
                    sidebarMenu(for: .following)
                    
                    Section(header: Text("Playlists")) {
                        ForEach(playlists, id: \.self) { playlist in
                            sidebarMenu(for: .playlist(playlist.title, playlist.id))
                        }
                    }
                }
            } detail: {
                NavigationStack {
                    detailView(for: navigationSelection)
                }
            }
            PlayerView()
        }
        .frame(minWidth: 800, minHeight: 400)
        .toolbar {
            ToolbarItem {
                TextField("􀊫 Search", text: $searchQuery)
                    .onExitCommand { searchQuery = "" }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 150)

            }
//            ToolbarItem {
//                MenuButton(label: Image(systemName: "arrow.up.arrow.down")) {
//                    Text("Recently Added")
//
//                }
//            }
//            ToolbarItem {
//                Button(action: { presentProfile = true }) {
//                    HStack {
//                        Text(SoundCloud.shared.user?.username ?? "Profile")
//                            .bold()
//                            .foregroundColor(.secondary)
//                        RemoteImage(url: SoundCloud.shared.user?.avatarURL, cornerRadius: 15)
//                            .frame(width: 30, height: 30)
//                    }
//                }
//                .buttonStyle(PlainButtonStyle())
//            }
        }
        .onAppear {            
            SoundCloud.shared.get(.library())
                .map { $0.collection }
                .replaceError(with: [])
                .receive(on: RunLoop.main)
                .sink { likes in
                    let playlists = likes.map { $0.item }
                    self.playlists = playlists
                    SoundCloud.shared.user?.playlists = playlists
                }
                .store(in: &self.subscriptions)
        }
    }
        
    @ViewBuilder private func sidebarMenu(for detail: NavigationDetail) -> some View {
        NavigationLink(value: detail) {
            HStack {
                if let imageName = detail.imageName {
                    Image(systemName: imageName)
                        .frame(width: 20, alignment: .center)
                }
                Text(detail.title)
            }
        }
    }
    
    @ViewBuilder private func detailView(for detail: NavigationDetail) -> some View {
        switch detail {
        case .stream:
            let stream = SoundCloud.shared.get(.stream())
            PostList(for: stream).navigationTitle(detail.title)
        case .likes:
            let likes = SoundCloud.shared.$user.filter { $0 != nil}
                .flatMap { SoundCloud.shared.get(.trackLikes(of: $0!)) }
                .eraseToAnyPublisher()
            TrackList(for: likes).navigationTitle(detail.title)
        case .history:
            let history = SoundCloud.shared.get(.history())
            TrackList(for: history).navigationTitle(detail.title)
        case .following:
            let following = SoundCloud.shared.$user.filter { $0 != nil }
                .flatMap { SoundCloud.shared.get(.followings(of: $0!)) }
                .eraseToAnyPublisher()
            UserGrid(for: following).navigationTitle(detail.title)
        case .playlist(_, let id):
            let ids = SoundCloud.shared.get(.playlist(id))
                .map { $0.trackIDs ?? [] }
                .eraseToAnyPublisher()
            let slice = { ids in
                return SoundCloud.shared.get(.tracks(ids))
            }
            TrackList(for: ids, slice: slice).navigationTitle(detail.title)
        }
    }
    
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}
