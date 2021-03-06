//
//  PlayerHand.swift
//  Blackjack
//
//  Created by Maciej Piotrowski on 9/3/19.
//

import PlayingCards

public struct PlayerHand: BettingHand {
    private var initialBet: UInt
    public var bet: UInt {
        return doubled ? initialBet * 2 : initialBet
    }

    public private(set) var cards: [Card]
    public init(bet: UInt, first: Card, second: Card) {
        initialBet = bet
        cards = [first, second]
    }

    public var options: HandOption {
        if outcome != .playing {
            return []
        }

        if cards.count > 2 {
            return .standard
        }

        if cards.count == 2 {
            return cards[0].blackjackValue == cards[1].blackjackValue ? .pair : .initial
        }

        return []
    }

    public var outcome: HandOutcome {
        if highValue == Int.Blackjack {
            return cards.count == 2 ? .blackjack : .stood
        } else if highValue > Int.Blackjack {
            return .bust
        } else if stood {
            return .stood
        } else if doubled {
            return .doubled
        }
        return .playing
    }

    public mutating func add(card: Card) {
        guard !stood else { return }
        cards.append(card)
        guard outcome == .doubled else { return }
        stand()
    }

    private var doubled = false
    public mutating func doubleBet() {
        guard cards.count == 2 else { return }
        doubled = true
    }

    private var stood = false
    public mutating func stand() {
        stood = true
    }
}

extension PlayerHand {
    init(bet: UInt, cards: [Card]) {
        precondition(cards.count >= 2)
        initialBet = bet
        self.cards = cards
    }
}
