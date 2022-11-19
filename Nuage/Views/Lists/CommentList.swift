//
//  CommentList.swift
//  Nuage
//
//  Created by Laurin Brandner on 19.02.21.
//

import SwiftUI
import Combine
import SoundCloud

struct CommentList: View {
    
    var publisher: InfinitePublisher<Comment>
    
    @EnvironmentObject private var player: StreamPlayer
    
    var body: some View {
        InfiniteList(publisher: publisher) { elements, idx -> AnyView in
            AnyView(CommentRow(comment: elements[idx]))
        }
    }
    
    init(for publisher: AnyPublisher<Slice<Comment>, Error>) {
        self.publisher = .slice(publisher)
    }
    
}
