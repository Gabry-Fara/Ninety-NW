import Foundation
import MultipeerConnectivity

/// Protocollo per ricevere eventi e messaggi dai peer
protocol MultipeerServiceDelegate: AnyObject {
    func didReceiveMessage(_ message: String, _ display_name: String)
    func peerDidConnect(_ peerID: MCPeerID)
    func peerDidDisconnect(_ peerID: MCPeerID)
}

class MultipeerService: NSObject {
    
    // MARK: - Proprietà base
    
    private var serviceType:String  // Nome "identificatore" del servizio (max 15 caratteri)
    
    /// Identificatore di questo peer (dispositivo)
    private let myPeerID: MCPeerID
    
    /// Sessione di connessione
    private let session: MCSession
    
    /// Advertiser: trasmette la nostra presenza ad altri peer (opzionale)
    private var advertiser: MCNearbyServiceAdvertiser?
    
    /// Browser: cerca i peer disponibili (opzionale)
    private var browser: MCNearbyServiceBrowser?
    
    /// Delegato per comunicare eventi e messaggi
    weak var delegate: MultipeerServiceDelegate?
    
    // MARK: - Init
    
    init(displayName: String = UIDevice.current.name, roomName: String) {
        self.serviceType = String(roomName.prefix(15)) // massimo 15 caratteri
        // displayName è il nome con cui ci presentiamo (default: nome random)
        let peerName = displayName
        print("Ciao, sono \(peerName) e il serviceType è \(serviceType)")
        // Inizializza il nostro peerID
        myPeerID = MCPeerID(displayName: peerName)
        
        // Crea la sessione
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        self.startBrowsing()
        self.startAdvertising()
        // Imposta il delegate della sessione su self
        session.delegate = self
    }
    
    // MARK: - Metodi pubblici
    
    /// Avvia l'advertiser
    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: nil,
                                               serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("[MultipeerService] Advertising avviato con nome: \(myPeerID.displayName)")
    }
    
    /// Ferma l'advertiser
    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        print("[MultipeerService] Advertising fermato.")
    }
    
    /// Avvia il browser
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("[MultipeerService] Browsing avviato con nome: \(myPeerID.displayName)")
    }
    
    /// Ferma il browser
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        print("[MultipeerService] Browsing fermato.")
    }
    
    /// Invia un messaggio di testo a tutti i peer connessi
    func send(message: String) {
        guard !session.connectedPeers.isEmpty else {
            print("[MultipeerService] Nessun peer connesso, impossibile inviare.")
            return
        }
        do {
            let data = Data(message.utf8)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("[MultipeerService] Messaggio inviato: \(message)")
        } catch {
            print("[MultipeerService] Errore inviando messaggio: \(error)")
        }
    }
    
    func disconnect() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
           session.disconnect()
       }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    // Chiamato quando lo stato di connessione di un peer cambia
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("[MultipeerService] Peer connesso: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.delegate?.peerDidConnect(peerID)
            }
        case .connecting:
            print("[MultipeerService] Connessione in corso con peer: \(peerID.displayName)")
        case .notConnected:
            print("[MultipeerService] Peer disconnesso: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.delegate?.peerDidDisconnect(peerID)
            }
        @unknown default:
            print("[MultipeerService] Stato sconosciuto per peer: \(peerID.displayName)")
        }
    }

    // Chiamato quando arrivano dati da un peer connesso
    // Indicates that an NSData object has been received from a nearby peer.
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print("[MultipeerService] Messaggio ricevuto: \(message) da \(peerID.displayName)")
            DispatchQueue.main.async {
                self.delegate?.didReceiveMessage(message, peerID.displayName)
            }
        }
    }
    
    // Called when a nearby peer opens a byte stream connection to the local peer.
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    
    // Indicates that the local peer began receiving a resource from a nearby peer.
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    
    // Indicates that the local peer finished receiving a resource from a nearby peer.
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    
    // Chiamato quando un browser ci invita a connetterci
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[MultipeerService] Invito ricevuto da \(peerID.displayName). Accetto.")
        // Accettiamo la connessione
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("[MultipeerService] Errore nell'advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    
    // Trovato un peer: possiamo invitarlo a connettersi
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        print("[MultipeerService] Trovato peer: \(peerID.displayName). Invio invito...")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    // Peer perso (non più visibile)
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        print("[MultipeerService] Perso peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("[MultipeerService] Errore nel browsing: \(error.localizedDescription)")
    }
}
