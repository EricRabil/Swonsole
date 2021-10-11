//
//  File.swift
//  
//
//  Created by Eric Rabil on 10/8/21.
//

import Foundation
import Swonsole

func bye() {
    ANSIViewRenderer.defaultRenderer.shutdown()
}

atexit(bye)
signal(SIGINT) { sig in
    exit(sig)
}

JumplistQuestion.ask(prompt: "Beeper Admin CLI", input: [
    ("a", "Change user channel")
]) { option in
    switch option {
    case "a":
        let users = ["ericrabil", "brad", "eric"]
        
        ListQuestion.ask(prompt: "Select user", input: users) { index in
            JumplistQuestion.ask(prompt: "Change channel for \(users[index])", input: [("n", "nightly"), ("i", "internal"), ("s", "stable")]) { index in
                exit(0)
            }.withActiveIndex(1)
        }
    default:
        break
    }
}

dispatchMain()
