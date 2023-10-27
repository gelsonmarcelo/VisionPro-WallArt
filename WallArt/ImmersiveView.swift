//
//  ImmersiveView.swift
//  WallArt
//
//  Created by Letras on 25/10/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

struct ImmersiveView: View {
    
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    
    private static let planeX: Float = 3.75
    private static let planeZ: Float = 2.625
    
    @State private var inputText = ""
    @State public var showTextField = false
    
    @State private var assistant: Entity? = nil
    @State private var waveAnimation: AnimationResource? = nil
    @State private var jumpAnimation: AnimationResource? = nil
    
    @State private var projectile: Entity? = nil
    
    @State public var showAttachmentButtons = false
    
    let tapSubject = PassthroughSubject<Void, Never>()
    @State var cancellable: AnyCancellable?
    
    @State var characterEntity: Entity = {
        let headAnchor = AnchorEntity(.head) //Ancoragem na câmera na cabeça do usuário
        headAnchor.position = [0.70, -0.35, -1] //Eixo X, Y, Z
        let radians = -30 * Float.pi / 180 //30 graus x pi / 180 -> Character agora está rotacionado 30 graus eixo Y
        ImmersiveView.rotateEntityAroundYAxis(entity: headAnchor, angle: radians)
        return headAnchor
    }()
    
    @State var planeEntity: Entity = {
        let wallAnchor = AnchorEntity(.plane(.vertical, classification: .wall, minimumBounds: SIMD2<Float>(0.6, 0.6))) //60 centimetros de altura e largura no mínimo dessa parede
        //Superfície largura 3.75m e 2.625m profundidade (pq profundidade ao invéz de altura é porque vamos colocar essa superfície na âncora da parede que segue com a superfície da parede, isso significa que o Y axis será perpendicular a parede)
        let planeMesh = MeshResource.generatePlane(width: Self.planeX, depth: Self.planeZ, cornerRadius: 0.1)
        //(Material) Cor verde
        let material = ImmersiveView.loadImageMaterial(imageUrl: "think_different")
        //Cria entidade com a superficie (malha) e cor (material)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        
        planeEntity.name = "canvas"
        wallAnchor.addChild(planeEntity)
        
        return wallAnchor
    }()
    
    var body: some View {
        RealityView { content, attachments in
            do {
                //Loading the entity called Immersive from realityKit
                let immersiveEntity = try await Entity(named: "Immersive", in: realityKitContentBundle)
                characterEntity.addChild(immersiveEntity)
                content.add(characterEntity)
                content.add(planeEntity)
                
                // Particle being set to false to start
                let projectileSceneEntity = try await Entity(named: "MainParticle", in: realityKitContentBundle)
                guard let projectile = projectileSceneEntity.findEntity(named: "ParticleRoot") else { return }
                projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                projectile.components.set(ProjectileComponent())
                characterEntity.addChild(projectile)
                
                // Impact Particle
                let impactParticleSceneEntity = try await Entity(named: "ImpactParticle", in: realityKitContentBundle)
                guard let impactParticle = impactParticleSceneEntity.findEntity(named: "ImpactParticle") else { return }
                impactParticle.position = [0, 0, 0]
                impactParticle.components[ParticleEmitterComponent.self]?.burstCount = 500
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.x = Self.planeX / 2.0 //same size of our canvas on the wall
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.z = Self.planeZ / 2.0
                planeEntity.addChild(impactParticle) //Added impactParicle to the canvas
                
                
                guard let attachmentEntity = attachments.entity(for: "attachment") else { return }
                attachmentEntity.position = SIMD3<Float>(0, 0.62, 0)
                let radians = 30 * Float.pi / 180
                ImmersiveView.rotateEntityAroundYAxis(entity: attachmentEntity, angle: radians)
                characterEntity.addChild(attachmentEntity)
                
                //identify assistant + applying basic animation
                let characterAnimationSceneEntity = try await Entity(named: "CharacterAnimations", in:
                realityKitContentBundle)
                guard let waveModel = characterAnimationSceneEntity.findEntity(named: "wave_model") else { return }
                guard let assistant = characterEntity.findEntity(named: "assistant") else { return }
                
                //Finding and getting animations from realityKitContent
                guard let jumpUpModel = characterAnimationSceneEntity.findEntity(named: "jump_up_model") else { return }
                guard let jumpFloatModel = characterAnimationSceneEntity.findEntity(named: "jump_float_model") else { return }
                guard let jumpDownModel = characterAnimationSceneEntity.findEntity(named: "jump_down_model") else { return }
                
                guard let idleAnimationResource = assistant.availableAnimations.first else { return }
                guard let waveAnimationResource = waveModel.availableAnimations.first else { return }
                let waveAnimation = try AnimationResource.sequence(with: [waveAnimationResource, idleAnimationResource.repeat()])
                assistant.playAnimation(idleAnimationResource.repeat())
                
                guard let jumpUpAnimationResource = jumpUpModel.availableAnimations.first else { return }
                guard let jumpFloatAnimationResource = jumpFloatModel.availableAnimations.first else { return }
                guard let jumpDownAnimationResource = jumpDownModel.availableAnimations.first else { return }
                
                //Complete animation jumping
                let jumpAnimation = try AnimationResource.sequence(with: [jumpUpAnimationResource, jumpFloatAnimationResource,
                    jumpDownAnimationResource, idleAnimationResource.repeat()])
            
                //Assign state asynchronously
                Task {
                    self.assistant = assistant
                    self.waveAnimation = waveAnimation
                    self.jumpAnimation = jumpAnimation
                    self.projectile = projectile
                }
            } catch {
                print("Error in RealityView's make: \(error)")
            }
        } attachments: {
            Attachment(id: "attachment") {
                VStack {
                    Text(inputText)
                        .frame(maxWidth: 600, alignment: .leading)
                        .font(.extraLargeTitle2)
                        .fontWeight(.regular)
                        .padding(40)
                        .glassBackgroundEffect()
                    if showAttachmentButtons {
                        HStack(spacing: 20) {
                            Button(action: {
                                tapSubject.send()
                            }) {
                                Text("Yes, let's go!")
                                    .font(.largeTitle)
                                    .fontWeight(.regular)
                                    .padding()
                                    .cornerRadius(8)
                            }
                            .padding()
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                //
                            }) {
                                Text("No")
                                    .font(.largeTitle)
                                    .fontWeight(.regular)
                                    .padding()
                                    .cornerRadius(8)
                            }
                            .padding()
                            .buttonStyle(.bordered)
                        }
                        .glassBackgroundEffect()
                        .opacity(showAttachmentButtons ? 1 : 0)
                    }
                }
                .opacity(showTextField ? 1 : 0)
            }
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { _ in
            viewModel.flowState = .intro //Setting flow state to intro when tap
        })
        .onChange(of: viewModel.flowState) { _, newValue in
            switch newValue {
                case .idle:
                    break
                case .intro:
                    playIntroSequence()
                
                case .projectileFlying:
                    if let projectile = self.projectile {
                        //hardcode the destination where the particle is going to move so that it always traverse
                        //towards the center of the simulator screen
                        //the reason we do that is because we cant get the real transform of the anchor entity
                        let dest = Transform(scale: projectile.transform.scale, rotation:
                                                projectile.transform.rotation, translation: [-0.7, 0.15, -0.5] * 2)
                        Task {
                            let duration = 3.0
                            projectile.position = [0, 0.1, 0]
                            projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = true
                            projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = true
                            projectile.move(to: dest, relativeTo: self.characterEntity, duration: duration,
                                            timingFunction: .easeInOut)
                            try? await Task.sleep(for: .seconds(duration))
                            projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                            projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                            viewModel.flowState = .updateWallArt
                        }
                    }
                    
                case .updateWallArt:
                    // somehow a system can't seem to access viewModel
                    // so here we update one of its static variable instead
                    self.projectile?.components[ProjectileComponent.self]?.canBurst = true
                    self.projectile?.components[ProjectileComponent.self]?.bursted = false
                
                    // update plane image
                    // actually calling a Doodle image gen model is irrelevant to Vision OS dev
                    // so we hardcoded the result image here
                    // you can easily do that by calling replicate's controlnet for example
                    // or run a control net locally
                    if let plane = planeEntity.findEntity(named: "canvas") as? ModelEntity {
                        plane.model?.materials = [ImmersiveView.loadImageMaterial(imageUrl: "sketch")]
                    }
                    
                    if let assistant = self.assistant, let jumpAnimation = self.jumpAnimation {
                        Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            assistant.playAnimation(jumpAnimation)
                            await animatePrompText(text: "Awesome!")
                            try? await Task.sleep(for: .milliseconds(500))
                            await animatePrompText(text: "What else do you want to see us\n build in Vision Pro at the end?")
                        }
                    }
            }
        }
    }
    
    func waitForButtonTap(using buttonTapPublisher: PassthroughSubject<Void, Never>) async {
        await withCheckedContinuation { continuation in
            let cancellable = tapSubject.first().sink(receiveValue: { _ in
                continuation.resume()
            })
            self.cancellable = cancellable
        }
    }
    
    func animatePrompText(text: String) async {
        //Type out the title.
        inputText = ""
        let words = text.split(separator: " ")
        for word in words {
            inputText.append(word + " ")
            let milliseconds = (1 + UInt64.random(in: 0...1)) * 100
            try? await Task.sleep(for: .milliseconds(milliseconds))
        }
    }
    
    func playIntroSequence() {
        Task {
            //show dialog box, its inside task because of async work
            if !showTextField {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTextField.toggle()
                }
            }
            
            if let assistant = self.assistant, let waveAnimation = self.waveAnimation {
                await assistant.playAnimation(waveAnimation.repeat(count: 1))
            }
            
            let texts = [
                "Hey :) Let's create some doodle art\n with the Vision Pro. Are you ready?",
                "Awesome. Draw something and\n watch it come alive.",
            ]
            
            await animatePrompText(text: texts[0])
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = true
            }
            
            await waitForButtonTap(using: tapSubject)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = false
            }
            
            Task {
                await animatePrompText(text: texts[1])
            }
            
            DispatchQueue.main.async {
                openWindow(id: "doodle_canvas")
            }
        }
    }
    
    static func rotateEntityAroundYAxis(entity: Entity, angle: Float) {
        //Get the current transform of the entity
        var currentTransform = entity.transform
        
        //Create a quaternion representing a rotation around the Y-axis
        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        
        //Combine the rotation with the current transform
        currentTransform.rotation = rotation * currentTransform.rotation
        
        //Apply the new transform to the entity
        entity.transform = currentTransform
    }
    
    static func loadImageMaterial(imageUrl: String) -> SimpleMaterial {
        do {
            let texture = try TextureResource.load(named: imageUrl) //Carrega imagem com URL
            var material = SimpleMaterial() //Cria um material
            //Cria uma cor com textura da imagem
            let color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
            material.color = color
            
            return material
        } catch {
            fatalError(String(describing: error))
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
