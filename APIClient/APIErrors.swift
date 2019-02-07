//
//  APIErrors.swift
//  InvoTrackerPE
//
//  Created by Ryan Sady on 1/27/19.
//  Copyright © 2019 Ryan Sady. All rights reserved.
//

import Foundation
import CoreLocation

public enum APIErrors: String, Error {
    case jsonParseError = "There was an error retrieving data from the server (JSON Parse).  Please try again.  If the issue persists please contact InvoTracker support."
    case noConnection = "No internet connection.  Check the connection and try again."
    case authError = "Authentication Error.  Please log out then log back in."
    case noIdError = "No id found.  If the issue persists please contact InvoTracker support."
}

extension String: Error {}
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
