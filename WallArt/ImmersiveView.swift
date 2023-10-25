//
//  ImmersiveView.swift
//  WallArt
//
//  Created by Letras on 25/10/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    
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
        let planeMesh = MeshResource.generatePlane(width: 3.75, depth: 2.625, cornerRadius: 0.1)
        //(Material) Cor verde
        let material = ImmersiveView.loadImageMaterial(imageUrl: "think_different")
        //Cria entidade com a superficie (malha) e cor (material)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        
        planeEntity.name = "canvas"
        wallAnchor.addChild(planeEntity)
        
        return wallAnchor
    }()
    
    var body: some View {
        RealityView { content in
            do {
                //Loading the entity called Immersive from realityKit
                let immersiveEntity = try await Entity(named: "Immersive", in: realityKitContentBundle)
                characterEntity.addChild(immersiveEntity)
                content.add(characterEntity)
                content.add(planeEntity)
            } catch {
                print("Error in RealityView's make: \(error)")
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
