//
//  GameImplTests.swift
//  BlackjackTests
//
//  Created by Maciej Piotrowski on 18/4/19.
//

import XCTest
import PlayingCards
@testable import Blackjack

final class GameImplTests: XCTestCase {
    
    var sut: GameImpl!
    var shoe: CardShoeSpy!
    var player: PlayerSpy!
    var dealer: DealerSpy!
    var stateNavigator: GameStateNavigatorSpy!

    override func setUp() {
        super.setUp()
        shoe = CardShoeSpy()
        player = PlayerSpy()
        dealer = DealerSpy()
        stateNavigator = GameStateNavigatorSpy()
        sut = GameImpl(shoe: shoe,
                       player: player,
                       dealer: dealer,
                       stateNavigator: stateNavigator)
    }

    override func tearDown() {
        sut = nil
        shoe = nil
        player = nil
        dealer = nil
        stateNavigator = nil
        super.tearDown()
    }
    
    //MARK: Betting & Reseting a bet
    func testBetChip() {
        //Given
        let chip = Chip.fifty
        
        //When
        sut.bet(chip)
        
        //Then
        XCTAssertEqual(sut.bet, 50)
        XCTAssertEqual(sut.state, .readyToPlay)
    }
    
    func testBetChips() {
        //Given
        let chip1 = Chip.ten
        let chip2 = Chip.fifty
        let chip3 = Chip.fiveHundered
        
        //When
        sut.bet(chip1)
        sut.bet(chip2)
        sut.bet(chip3)

        //Then
        XCTAssertEqual(sut.bet, 560)
        XCTAssertEqual(sut.state, .readyToPlay)
    }
    
    func testBettingIsImpossibleDuringTheRound() {
        //Given
        stateNavigator.state = .playersTurn
        
        //When
        sut.bet(.fifty)
        
        //Then
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(sut.state, .playersTurn)
        XCTAssertNil(player.receivedChips)
    }
    
    func testBetIsEqualToPlayersHandBetDuringTheRound() {
        //Given
        let bet: UInt = 300
        player.hand = PlayerHand.sampleHand(with: bet)
        stateNavigator.state = .playersTurn
        
        //When
        sut.bet(.fifty)
        
        //Then
        XCTAssertEqual(sut.bet, bet)
        XCTAssertEqual(sut.state, .playersTurn)
        XCTAssertNil(player.receivedChips)
    }
    
    func testResetting() {
        //Given
        sut.bet(.ten)
        XCTAssertEqual(sut.bet, 10)

        //When
        sut.reset()
        
        //Then
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(sut.state, .readyToPlay)
        XCTAssertEqual(player.receivedChips, 10)
        
    }
    
    func testResettingIsImpossibleDuringTheRound() {
        //Given
        let bet: UInt = 300
        player.hand = PlayerHand.sampleHand(with: bet)
        stateNavigator.state = .playersTurn

        //When
        sut.reset()
        
        //Then
        XCTAssertEqual(sut.bet, bet)
        XCTAssertEqual(sut.state, .playersTurn)
        XCTAssertNil(player.receivedChips)
    }
    
    //MARK: Hands
    func testGameGetsHandFromDealer() {
        //Given
        dealer.hand = DealerHand.sampleHand()
        
        //When
        let hand = sut.dealerHand
        
        //Then
        XCTAssertTrue(hand! == dealer.hand!)
    }
    
    func testGameGetsHandFromPlayer() {
        //Given
        player.hand = PlayerHand.sampleHand()
        
        //When
        let hand = sut.playerHand
        
        //Then
        XCTAssertTrue(hand! == player.hand!)
    }
    
    //MARK: Playing
    func testPlayImpossibleIfThereIsNoBet() {
        //Given
        //no betting
        
        //When
        XCTAssertNoThrow(try sut.play())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
        
    }
    
    func testPlayChangesStateToPlayersTurn() {
        //Given
        shoe.prepareCards()
        sut.bet(.ten)
        
        //When
        XCTAssertNoThrow(try sut.play())

        //Then
        XCTAssertEqual(stateNavigator.navigatedToState, .playersTurn)
    }
    
    func testPlayGets4CardsFromTheShoe() {
        //Given
        shoe.prepareCards()
        sut.bet(.ten)
        
        //When
        XCTAssertNoThrow(try sut.play())

        //Then
        XCTAssertEqual(shoe.dealCount, 4)
    }
    
    func testPlayCannotBeStartedMultipleTimes() {
        //Given
        stateNavigator.state = .playersTurn
        
        //When
        XCTAssertThrowsError(try self.sut.play(), "Should throw GameError.roundInProgress error")

        //Then
        XCTAssertEqual(shoe.dealCount, 0)
        XCTAssertEqual(stateNavigator.navigatedToStateCount, 0)
    }
    
    func testPlayCreatesPlayersAndDealersHands() {
        //Given
        shoe.prepareCards()
        sut.bet(.fiveHundered)
        let bet = sut.bet
        
        //When
        XCTAssertNoThrow(try sut.play())

        //Then
        XCTAssertNotNil(player.createdHandWithCards)
        XCTAssertEqual(player.createdHandWithBet, bet)
        XCTAssertNotNil(dealer.createdHandWithCards)
    }
    
    func testPlayCreatesPlayersAndDealersHandsWithCorrectCards() {
        //Given
        let cards = shoe.prepareCards()
        sut.bet(.ten)
        
        //When
        XCTAssertNoThrow(try sut.play())

        //Then
        XCTAssertEqual(player.createdHandWithCards?.count, 2)
        XCTAssertEqual(dealer.createdHandWithCards?.count, 2)
        
        XCTAssertEqual(player.createdHandWithCards?.first, cards[0])
        XCTAssertEqual(dealer.createdHandWithCards?.first, cards[1])
        XCTAssertEqual(player.createdHandWithCards?.last, cards[2])
        XCTAssertEqual(dealer.createdHandWithCards?.last, cards[3])
    }
    
    func testPlayTellsPlayerToPlayTheirHand() {
        //Given
        shoe.prepareCards()
        sut.bet(.ten)
        
        //When
        XCTAssertNoThrow(try sut.play())

        //Then
        XCTAssertTrue(player.playHandCalled)
    }
    
    func testPlay_WhenThereAreNoCardsInTheShoe() {
        //Given
        shoe.cards = []
        sut.bet(.ten)

        //When
        XCTAssertThrowsError(try sut.play(), "Should throw GameError.cardShoeEmpty error")

        //Then
        XCTAssertNil(player.createdHandWithCards)
        XCTAssertNil(sut.dealerHand)
    }
    
    //MARK: Dealing cards
    func testDealCardIsPossibleWhenStateIsPlayersTurn() {
        //Given
        stateNavigator.state = .playersTurn
        let expectedCard = Card.sampleCard()
        shoe.prepareCards([expectedCard])
        
        //When
        let card = try! sut.dealCard()
        
        //Then
        XCTAssertEqual(card, expectedCard)
    }

    func testDealCardDoesntThrowAnErrorWhenStateIsPlayersTurn() {
        //Given
        stateNavigator.state = .playersTurn
        shoe.prepareCards()
        
        //When
        XCTAssertNoThrow(try sut.dealCard())
        
        //Then
        //Doesn't throw an error
    }
    
    func testDealCardThrowsWhenShoeIsEmptyAndStateIsPlayersTurn() {
        //Given
        stateNavigator.state = .playersTurn
        shoe.prepareCards([])
        
        //When
        XCTAssertThrowsError(try sut.dealCard())
        
        //Then
        //Throws an error
    }
    
    func testDealCardDoesntThrowAnErrorWhenStateIsDealersTurn() {
        //Given
        stateNavigator.state = .dealersTurn
        let expectedCard = Card.sampleCard()
        shoe.prepareCards([expectedCard])
        
        //When
        let card = try! sut.dealCard()
        
        //Then
        XCTAssertEqual(card, expectedCard)
    }
    
    func testDealCardIsPossibleWhenStateIsDealersTurn() {
        //Given
        stateNavigator.state = .dealersTurn
        shoe.prepareCards()
        
        //When
        XCTAssertNoThrow(try sut.dealCard())
        
        //Then
        //Doesn't throw an error
    }
    
    func testDealCardThrowsWhenShoeIsEmptyAndStateIsDealersTurn() {
        //Given
        stateNavigator.state = .dealersTurn
        shoe.prepareCards([])
        
        //When
        XCTAssertThrowsError(try sut.dealCard())
        
        //Then
        //Throws an error
    }
    
    func testDealCardThrowsWhenPlayIsNotInProgress_readyToPlay() {
        //Given
        stateNavigator.state = .readyToPlay
        shoe.prepareCards()

        //When
        XCTAssertThrowsError(try sut.dealCard())
        
        //Then
        //Error is thrown
    }
    
    func testDealCardThrowsWhenPlayIsNotInProgress_managingBets() {
        //Given
        stateNavigator.state = .managingBets
        shoe.prepareCards()

        //When
        XCTAssertThrowsError(try sut.dealCard())
        
        //Then
        //Error is thrown
    }
  
    //MARK: Finishing Player's Turn
    func testFinishPlayerTurnNavigatesToDealersTurn() {
        //Given
        stateNavigator.state = .playersTurn
        
        //When
        XCTAssertNoThrow(try sut.finishPlayersTurn())
        
        //Then
        XCTAssertEqual(stateNavigator.navigatedToState, .dealersTurn)
    }
    
    func testFinishPlayerTurnThrowsWhenStateIs_ReadyToPlay() {
        //Given
        stateNavigator.state = .readyToPlay
        
        //When
        XCTAssertThrowsError(try sut.finishPlayersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    func testFinishPlayerTurnThrowsWhenStateIs_DealersTurn() {
        //Given
        stateNavigator.state = .dealersTurn
        
        //When
        XCTAssertThrowsError(try sut.finishPlayersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    func testFinishPlayerTurnThrowsWhenStateIs_managingBets() {
        //Given
        stateNavigator.state = .managingBets
        
        //When
        XCTAssertThrowsError(try sut.finishPlayersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    func testFinishPlayersTurnTellsDealerToPlayTheirHand() {
        //Given
        stateNavigator.state = .playersTurn
        
        //When
        try? sut.finishPlayersTurn()
        
        //Then
        XCTAssertTrue(dealer.playHandCalled)
    }
    
    //MARK: Finishing Dealer's Turn
    func testFinishDealersTurn_DoesNotThrow_AndDiscardsCardsWhenBothHandsExist() {
        //Given
        stateNavigator.state = .dealersTurn
        let playerHand = PlayerHand.sampleHand()
        let dealerHand = DealerHand.sampleHand()
        player.hand = playerHand
        dealer.hand = dealerHand
        
        //When
        XCTAssertNoThrow(try sut.finishDealersTurn())
        
        //Then
        let expectedCardsCount = playerHand.cards.count + dealerHand.cards.count
        XCTAssertEqual(shoe.discardedCards.count, expectedCardsCount)
    }
    
    func testFinishDealersTurnThrowsWhenStateIs_PlayersTurn() {
        //Given
        stateNavigator.state = .playersTurn
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    func testFinishDealersTurnThrowsWhenStateIs_ReadyToPlay() {
        //Given
        stateNavigator.state = .readyToPlay
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    func testFinishDealersTurnThrowsWhenStateIs_ManagingBets() {
        //Given
        stateNavigator.state = .managingBets
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())
        
        //Then
        XCTAssertNil(stateNavigator.navigatedToState)
    }
    
    //MARK: Comparing Hands & Managing Bets
    func testFinishDealersTurn_ThrowsWhenThereIsNoDealersHand() {
        //Given
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleHand()
        dealer.hand = nil
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())

        //Then
        //It throws an error
    }
    
    func testFinishDealersTurn_ThrowsWhenThereIsNoPlayersHand() {
        //Given
        stateNavigator.state = .dealersTurn
        player.hand = nil
        dealer.hand = DealerHand.sampleHand()
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())
        
        //Then
        //It throws an error
    }
    
    func testFinishDealersTurn_ThrowsWhenThereAreNoHands() {
        //Given
        stateNavigator.state = .dealersTurn
        player.hand = nil
        dealer.hand = nil
        
        //When
        XCTAssertThrowsError(try sut.finishDealersTurn())
        
        //Then
        //It throws an error
    }
    
    func testFinishDealersTurn_AsksToDiscardHands() {
        //Given
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleHand()
        dealer.hand = DealerHand.sampleHand()

        //When
        try? sut.finishDealersTurn()

        //Then
        XCTAssertTrue(player.discardHandCalled)
        XCTAssertTrue(dealer.discardHandCalled)
    }
    
    //MARK: Draw
    func testFinishDealersTurnLeadsToADraw_1() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleBlackjackHand(with: bet)
        dealer.hand = DealerHand.sampleBlackjackHand()
        let payout = bet

        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToADraw_2() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample21Hand(with: bet)
        dealer.hand = DealerHand.sample21Hand()
        let payout = bet
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }

    func testFinishDealersTurnLeadsToADraw_3() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample17Hand(with: bet)
        dealer.hand = DealerHand.sample17Hand()
        let payout = bet
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToADraw_4() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample18Hand(with: bet)
        dealer.hand = DealerHand.sample18Hand()
        let payout = bet
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToADraw_5() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleBlackjackHand(with: bet)
        player.hand!.doubleBet()
        XCTAssertEqual(player.hand?.bet, 200)
        dealer.hand = DealerHand.sampleBlackjackHand()
        let payout: UInt = 200
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    //MARK: Player wins
    func testFinishDealersTurnLeadsToPlayerWinning_1() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleBlackjackHand(with: bet)
        dealer.hand = DealerHand.sample21Hand()
        let payout: UInt = 250
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToPlayerWinning_2() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleBlackjackHand(with: bet)
        dealer.hand = DealerHand.sample17Hand()
        let payout: UInt = 250

        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToPlayerWinning_3() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample19Hand(with: bet)
        dealer.hand = DealerHand.sample18Hand()
        let payout: UInt = 200
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToPlayerWinning_4() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample20_2card_Hand(with: bet)
        player.hand!.doubleBet()
        XCTAssertEqual(player.hand?.bet, 200)
        dealer.hand = DealerHand.sample18Hand()
        let payout: UInt = 400
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    func testFinishDealersTurnLeadsToPlayerWinning_5() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sampleBlackjackHand(with: bet)
        player.hand!.doubleBet()
        dealer.hand = DealerHand.sample18Hand()
        let payout: UInt = 500
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertEqual(player.receivedChips, payout)
        XCTAssertEqual(sut.bet, 0)
    }
    
    
    //MARK: Dealer wins
    func testFinishDealersTurnLeadsToDealerWinning_1() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample21Hand(with: bet)
        dealer.hand = DealerHand.sampleBlackjackHand()
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertNil(player.receivedChips)
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(dealer.collectedBet, 100)
    }
    
    func testFinishDealersTurnLeadsToDealerWinning_2() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample18Hand(with: bet)
        dealer.hand = DealerHand.sampleBlackjackHand()
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertNil(player.receivedChips)
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(dealer.collectedBet, 100)
    }
    
    func testFinishDealersTurnLeadsToDealerWinning_3() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample17Hand(with: bet)
        dealer.hand = DealerHand.sample18Hand()
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertNil(player.receivedChips)
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(dealer.collectedBet, 100)
    }
    
    
    func testFinishDealersTurnLeadsToDealerWinning_4() {
        //Given
        let bet: UInt = 100
        stateNavigator.state = .dealersTurn
        player.hand = PlayerHand.sample19_2card_Hand(with: bet)
        player.hand!.doubleBet()
        dealer.hand = DealerHand.sampleBlackjackHand()
        
        //When
        try? sut.finishDealersTurn()
        
        //Then
        XCTAssertNil(player.receivedChips)
        XCTAssertEqual(sut.bet, 0)
        XCTAssertEqual(dealer.collectedBet, 200)
    }
    
    
}
