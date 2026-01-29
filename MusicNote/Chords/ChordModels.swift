//
//  ChordModels.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import Foundation

enum ChordInversion: String, CaseIterable {
    case root = "Root"
    case first = "1st"
    case second = "2nd"
}

struct ChordPractice {
    let imageName: String
    let numeral: String      // I, ii, iii, IV, V, vi, vii°
    let inversion: ChordInversion
}

