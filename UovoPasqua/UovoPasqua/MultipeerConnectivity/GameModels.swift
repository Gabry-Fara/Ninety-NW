import Foundation

// MARK: - Game Enums
public enum Move: String, Codable {
    case rock, paper, scissors
}

public enum RoundResult: String, Codable {
    case win, lose, draw
}

// MARK: - Core Game Packet
public enum GamePacket: Codable {
    case lobbyStatus(playerCount: Int)
    case matchStarted(opponentName: String)
    case makeMove(choice: Move) // .rock, .paper, .scissors
    case gameResult(result: RoundResult, opponentMove: Move)
}
