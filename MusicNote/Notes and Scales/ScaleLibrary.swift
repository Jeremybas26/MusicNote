//
//  ScaleLibrary.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

// MARK: - Scale Model
struct Scale {
    let name: String
    let imageName: String
}

// MARK: - Scales Library (12 unique major keys, no enharmonic duplicates)
let majorScales: [Scale] = [
    Scale(name: "C Major", imageName: "C major"),
    Scale(name: "G Major", imageName: "G major"),
    Scale(name: "D Major", imageName: "D major"),
    Scale(name: "A Major", imageName: "A major"),
    Scale(name: "E Major", imageName: "E major"),
    Scale(name: "B Major", imageName: "B major"),
    Scale(name: "F# Major", imageName: "F sharp major"),
    Scale(name: "C# Major", imageName: "C sharp major"),

    Scale(name: "F Major", imageName: "F major"),
    Scale(name: "Bb Major", imageName: "B flat major"),
    Scale(name: "Eb Major", imageName: "E flat major"),
    Scale(name: "Ab Major", imageName: "A flat major")
]
