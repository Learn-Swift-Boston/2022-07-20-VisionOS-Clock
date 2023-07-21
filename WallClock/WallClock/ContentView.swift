//
//  ContentView.swift
//  WallClock
//
//  Created by Zev Eisenberg on 7/20/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

let arSession = ARKitSession()
let sceneReconstruction = SceneReconstructionProvider(modes: [])

struct ContentView: View {

    @State var hoursAngle: Angle = .degrees(135)
    @State var minutesAngle: Angle = .degrees(135)
    @State var secondsAngle: Angle = .zero

    private let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()

    var body: some View {
        VStack {
            RealityView { content in
                // Add the initial RealityKit content
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                    content.add(scene)
                }
            } update: { content in
                if let scene = content.entities.first?.scene {
                    print(scene.anchors)
                }

                // Update the RealityKit content when SwiftUI state changes
                let entities = content.entities
                guard let firstEntity = entities.first else {
                    return
                }

                let children = firstEntity.children
                guard let root = children.first(where: { $0.name == "Root" }) else {
                    return
                }

                let rootChildren = root.children
                guard let clockFaceRoot = rootChildren.first(where: { $0.name == "clockFaceAgain" }) else {
                    return
                }

                let clockChildren = clockFaceRoot.children

                print(clockChildren.map(\.name))
                if let secondHand = clockChildren.first(where: { $0.name == "secondHand" }) {
                    secondHand.transform.rotation = simd_quatf(
                        Rotation3D(
                            eulerAngles: EulerAngles(
                                x: .zero,
                                y: .zero,
                                z: .init(degrees: secondsAngle.degrees),
                                order: .xyz
                            )
                        )
                    )
                }

                if let minuteHand = clockChildren.first(where: { $0.name == "minuteHand" }) {
                    minuteHand.transform.rotation = simd_quatf(
                        Rotation3D(
                            eulerAngles: EulerAngles(
                                x: .zero,
                                y: .zero,
                                z: .init(degrees: minutesAngle.degrees),
                                order: .xyz
                            )
                        )
                    )
                }

                if let hourHand = clockChildren.first(where: { $0.name == "hourHand" }) {
                    hourHand.transform.rotation = simd_quatf(
                        Rotation3D(
                            eulerAngles: EulerAngles(
                                x: .zero,
                                y: .zero,
                                z: .init(degrees: hoursAngle.degrees),
                                order: .xyz
                            )
                        )
                    )
                }
            }
        }
        .onReceive(timer) { _ in
            let date = Date()
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)

            guard let hours = components.hour?.quotientAndRemainder(dividingBy: 12).remainder,
                  let minutes = components.minute,
                  let seconds = components.second else {
                return
            }

            print("\(hours):\(minutes):\(seconds)")

            let fractionalHour = Double(minutes) / 60
            hoursAngle = -.degrees((Double(hours) + fractionalHour) * 30) + .degrees(135)
            minutesAngle = -.degrees(Double(minutes * 6)) + .degrees(135)
            secondsAngle = -.degrees(Double(seconds * 6))
        }
        .task {
            do {
                try await arSession.run([sceneReconstruction])
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
