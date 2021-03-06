//
//  CleanupOpertion.swift
//  Mendoza
//
//  Created by tomas on 05/03/2019.
//

import Foundation

class CleanupOperation: BaseOperation<Void> {
    private let configuration: Configuration
    private let timestamp: String
    private lazy var executer: Executer? = {
        let destinationNode = configuration.resultDestination.node
        
        let logger = ExecuterLogger(name: "\(type(of: self))", address: destinationNode.address)
        return try? destinationNode.makeExecuter(logger: logger)
    }()
    
    init(configuration: Configuration, timestamp: String) {
        self.configuration = configuration
        self.timestamp = timestamp
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        do {
            didStart?()
            
            guard let executer = executer else { fatalError("💣 Failed making executer") }
            
            try reclaimDiskSpace(executer: executer)
            
            didEnd?(())
        } catch {
            didThrow?(error)
        }
    }
    
    override func cancel() {
        if isExecuting {
            executer?.terminate()
        }
        super.cancel()
    }

    private func reclaimDiskSpace(executer: Executer) throws {
        let destinationPath = "\(self.configuration.resultDestination.path)/\(self.timestamp)"
        
        // remove all partial coverage files that were merged together
        _ = try executer.execute("find '\(destinationPath)' -type d -name 'ProfileData' -exec rm -r {} +")
    }
}
