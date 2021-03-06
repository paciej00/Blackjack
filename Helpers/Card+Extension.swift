//
//  Card+Extension.swift
//  BlackjackTests
//
//  Created by Maciej Piotrowski on 19/4/19.
//

import PlayingCards

extension Card {
    static func sample4() -> [Card] {
        return [
            Card(suit: .clubs, rank: .queen),
            Card(suit: .diamonds, rank: .ace),
            Card(suit: .spades, rank: .four),
            Card(suit: .hearts, rank: .two),
        ]
    }

    static func sample2() -> [Card] {
        return [
            Card(suit: .clubs, rank: .queen),
            Card(suit: .spades, rank: .four),
        ]
    }

    static func sampleCard() -> Card {
        return sample(.ten)
    }

    static func sample(_ rank: Rank = .two) -> Card {
        return Card(suit: .clubs, rank: rank)
    }
}
