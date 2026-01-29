//
//  ChordLibrary.swift
//  MusicNote
//
//  Created by Jeremy Bastidas on 1/3/26.
//

import Foundation

enum ChordKey: String {
    case c, g, d, a, e, b, fsharp, csharp, f, bflat, eflat, aflat
}

// MARK: - Chord Note Generation (for Piano Practice)

extension ChordLibrary {

    static func notes(
        for numeral: String,
        in key: ChordKey,
        inversion: ChordInversion
    ) -> [String] {

        // Basic major scale for each key (normalized note names)
        let majorScales: [ChordKey: [String]] = [
            .c: ["C","D","E","F","G","A","B"],
            .g: ["G","A","B","C","D","E","F#"],
            .d: ["D","E","F#","G","A","B","C#"],
            .a: ["A","B","C#","D","E","F#","G#"],
            .e: ["E","F#","G#","A","B","C#","D#"],
            .b: ["B","C#","D#","E","F#","G#","A#"],
            .fsharp: ["F#","G#","A#","B","C#","D#","E#"],
            .csharp: ["C#","D#","E#","F#","G#","A#","B#"],
            .f: ["F","G","A","Bb","C","D","E"],
            .bflat: ["Bb","C","D","Eb","F","G","A"],
            .eflat: ["Eb","F","G","Ab","Bb","C","D"],
            .aflat: ["Ab","Bb","C","Db","Eb","F","G"]
        ]

        guard let scale = majorScales[key] else { return [] }

        // Map roman numeral to scale degree
        let degreeIndex: Int
        switch numeral.lowercased() {
        case "i": degreeIndex = 0
        case "ii": degreeIndex = 1
        case "iii": degreeIndex = 2
        case "iv": degreeIndex = 3
        case "v": degreeIndex = 4
        case "vi": degreeIndex = 5
        case "vii°", "vii": degreeIndex = 6
        default: return []
        }

        // Build triad (1–3–5)
        let root = scale[degreeIndex % 7]
        let third = scale[(degreeIndex + 2) % 7]
        let fifth = scale[(degreeIndex + 4) % 7]

        var notes = [root, third, fifth]

        // Apply inversion
        switch inversion {
        case .root:
            break
        case .first:
            notes = [third, fifth, root]
        case .second:
            notes = [fifth, root, third]
        }

        return notes
    }
}

// MARK: - Chord Library

struct ChordLibrary {

    static let cMajor: [ChordPractice] = [
        // I
        ChordPractice(imageName: "chordci_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordci_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordci_2nd", numeral: "I", inversion: .second),

        // ii
        ChordPractice(imageName: "chordcii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordcii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordcii_2nd", numeral: "ii", inversion: .second),

        // iii
        ChordPractice(imageName: "chordciii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordciii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordciii_2nd", numeral: "iii", inversion: .second),

        // IV
        ChordPractice(imageName: "chordciv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordciv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordciv_2nd", numeral: "IV", inversion: .second),

        // V
        ChordPractice(imageName: "chordcv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordcv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordcv_2nd", numeral: "V", inversion: .second),

        // vi
        ChordPractice(imageName: "chordcvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordcvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordcvi_2nd", numeral: "vi", inversion: .second),

        // vii°
        ChordPractice(imageName: "chordcvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordcvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordcvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - G Major
    static let gMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordgi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordgi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordgi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordgii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordgii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordgii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordgiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordgiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordgiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordgiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordgiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordgiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordgv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordgv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordgv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordgvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordgvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordgvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordgvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordgvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordgvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - D Major
    static let dMajor: [ChordPractice] = [
        ChordPractice(imageName: "chorddi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chorddi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chorddi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chorddii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chorddii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chorddii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chorddiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chorddiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chorddiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chorddiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chorddiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chorddiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chorddv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chorddv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chorddv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chorddvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chorddvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chorddvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chorddvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chorddvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chorddvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - A Major
    static let aMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordai_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordai_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordai_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordaii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordaii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordaii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordaiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordaiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordaiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordaiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordaiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordaiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordav_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordav_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordav_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordavi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordavi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordavi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordavii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordavii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordavii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - E Major
    static let eMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordei_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordei_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordei_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordeii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordeii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordeii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordeiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordeiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordeiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordeiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordeiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordeiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordev_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordev_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordev_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordevi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordevi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordevi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordevii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordevii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordevii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - B Major
    static let bMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordbi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordbi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordbi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordbii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordbii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordbii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordbiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordbiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordbiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordbiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordbiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordbiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordbv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordbv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordbv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordbvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordbvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordbvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordbvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordbvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordbvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - F# Major
    static let fsharpMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordfsharpi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordfsharpi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordfsharpi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordfsharpii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordfsharpii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordfsharpii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordfsharpiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordfsharpiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordfsharpiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordfsharpiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordfsharpiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordfsharpiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordfsharpv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordfsharpv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordfsharpv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordfsharpvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordfsharpvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordfsharpvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordfsharpvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordfsharpvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordfsharpvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - C# Major
    static let csharpMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordcsharpi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordcsharpi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordcsharpi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordcsharpii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordcsharpii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordcsharpii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordcsharpiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordcsharpiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordcsharpiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordcsharpiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordcsharpiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordcsharpiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordcsharpv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordcsharpv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordcsharpv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordcsharpvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordcsharpvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordcsharpvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordcsharpvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordcsharpvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordcsharpvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - F Major
    static let fMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordfi_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordfi_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordfi_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordfii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordfii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordfii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordfiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordfiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordfiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordfiv_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordfiv_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordfiv_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordfv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordfv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordfv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordfvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordfvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordfvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordfvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordfvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordfvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - Bb Major
    static let bflatMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordbflati_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordbflati_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordbflati_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordbflatii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordbflatii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordbflatii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordbflatiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordbflatiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordbflatiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordbflativ_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordbflativ_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordbflativ_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordbflatv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordbflatv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordbflatv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordbflatvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordbflatvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordbflatvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordbflatvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordbflatvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordbflatvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - Eb Major
    static let eflatMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordeflati_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordeflati_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordeflati_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordeflatii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordeflatii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordeflatii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordeflatiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordeflatiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordeflatiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordeflativ_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordeflativ_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordeflativ_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordeflatv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordeflatv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordeflatv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordeflatvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordeflatvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordeflatvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordeflatvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordeflatvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordeflatvii_2nd", numeral: "vii°", inversion: .second)
    ]

    // MARK: - Ab Major
    static let aflatMajor: [ChordPractice] = [
        ChordPractice(imageName: "chordaflati_root", numeral: "I", inversion: .root),
        ChordPractice(imageName: "chordaflati_1st", numeral: "I", inversion: .first),
        ChordPractice(imageName: "chordaflati_2nd", numeral: "I", inversion: .second),

        ChordPractice(imageName: "chordaflatii_root", numeral: "ii", inversion: .root),
        ChordPractice(imageName: "chordaflatii_1st", numeral: "ii", inversion: .first),
        ChordPractice(imageName: "chordaflatii_2nd", numeral: "ii", inversion: .second),

        ChordPractice(imageName: "chordaflatiii_root", numeral: "iii", inversion: .root),
        ChordPractice(imageName: "chordaflatiii_1st", numeral: "iii", inversion: .first),
        ChordPractice(imageName: "chordaflatiii_2nd", numeral: "iii", inversion: .second),

        ChordPractice(imageName: "chordaflativ_root", numeral: "IV", inversion: .root),
        ChordPractice(imageName: "chordaflativ_1st", numeral: "IV", inversion: .first),
        ChordPractice(imageName: "chordaflativ_2nd", numeral: "IV", inversion: .second),

        ChordPractice(imageName: "chordaflatv_root", numeral: "V", inversion: .root),
        ChordPractice(imageName: "chordaflatv_1st", numeral: "V", inversion: .first),
        ChordPractice(imageName: "chordaflatv_2nd", numeral: "V", inversion: .second),

        ChordPractice(imageName: "chordaflatvi_root", numeral: "vi", inversion: .root),
        ChordPractice(imageName: "chordaflatvi_1st", numeral: "vi", inversion: .first),
        ChordPractice(imageName: "chordaflatvi_2nd", numeral: "vi", inversion: .second),

        ChordPractice(imageName: "chordaflatvii_root", numeral: "vii°", inversion: .root),
        ChordPractice(imageName: "chordaflatvii_1st", numeral: "vii°", inversion: .first),
        ChordPractice(imageName: "chordaflatvii_2nd", numeral: "vii°", inversion: .second)
    ]

    static func all(for key: ChordKey) -> [ChordPractice] {
        switch key {
        case .c: return cMajor
        case .g: return gMajor
        case .d: return dMajor
        case .a: return aMajor
        case .e: return eMajor
        case .b: return bMajor
        case .fsharp: return fsharpMajor
        case .csharp: return csharpMajor
        case .f: return fMajor
        case .bflat: return bflatMajor
        case .eflat: return eflatMajor
        case .aflat: return aflatMajor
        }
    }
}
