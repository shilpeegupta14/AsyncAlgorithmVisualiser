//
//  Algorithms.swift
//  AsyncAlgoVisualiser
//
//  Created by Shilpee Gupta on 11/01/23.
//

import Foundation
import AsyncAlgorithms

enum Algorithm: String, CaseIterable, Identifiable {
    case merge
    case chain
    case zip
    case combineLatest
    case adjacentPairs
    
    var id: Self {
        self
    }
    
    func getDescription() -> String {
        switch self {
        case .merge:
            return "Merges two or more asynchronous sequence into a single asynchronous sequence producing the elements of all of the underlying asynchronous sequences."
        case .chain:
            return " Concatenates two or more asynchronous sequences with the same element type."
        case .zip:
            return "Creates an asynchronous sequence of pairs built out of underlying asynchronous sequences."
        case .combineLatest:
            return "Combines two or more asynchronous sequences into an asynchronous sequence producing a tuple of elements from those base asynchronous sequences that updates when any of the base sequences produce a value."
        case .adjacentPairs:
            return "Collects adjacent values of asynchronous sequence and produces elements of tuple (size of 2)."
        }
    }
}

extension Array where Element == Event {
    @MainActor
    func stream(speedFactor: Double) -> AsyncStream<Event> {
        AsyncStream { cont in
            let events = sorted()
            for event in events {
                Timer.scheduledTimer(withTimeInterval: event.time/speedFactor, repeats: false) { _ in
                    cont.yield(event)
                    if event == events.last {
                        cont.finish()
                    }
                }
            }
        }
    }
}

func run(algorithm: Algorithm, _ events1: [Event], _ events2: [Event]) async -> [Event] {
    let factor: Double = 10
    let stream1 = await events1.stream(speedFactor: factor)
    let stream2 = await events2.stream(speedFactor: factor)
    
    var result: [Event] = []
    let startDate = Date()
    var interval: TimeInterval { Date().timeIntervalSince(startDate) * factor }


    switch algorithm {
    case .merge:
        for await event in merge(stream1, stream2) {
            result.append(Event(id: event.id, time: interval, color: event.color, value: event.value))
        }
    case .chain:
        for await event in chain(stream1, stream2) {
            result.append(Event(id: event.id, time: interval, color: event.color, value: event.value))
        }
    case .zip:
        for await (e1, e2) in zip(stream1, stream2) {
            result.append(Event(id: .combined(e1.id, e2.id), time: interval, color: .blue, value: .combined(e1.value, e2.value)))
        }
    case .combineLatest:
        for await (e1, e2) in combineLatest(stream1, stream2) {
            result.append(Event(id: .combined(e1.id, e2.id), time: interval, color: .blue, value: .combined(e1.value, e2.value)))
        }
    case .adjacentPairs:
        for await (e1, e2) in stream1.adjacentPairs() {
            result.append(Event(id: .combined(e1.id, e2.id), time: interval, color: .blue, value: .combined(e1.value, e2.value)))
        }
    }
    return result
}
