//
//  ObjMeshLoader.swift
//  NavMeshDemo
//
//  Created by Miguel de Icaza on 8/22/23.
//

import Foundation
import RealityKit

/// Very simple mesh loader, only supports 'v' and 'f' commands, intended purely to show the demos
class ObjMeshLoader {
    enum LoadError: Error {
        case invalidFormat
        case unsupportedFeature (String)
        
        var localizedDescription: String {
            switch self {
            case .invalidFormat:
                return "Invalid Format"
            case .unsupportedFeature(let s):
                return "Unsupported format feature: \(s)"
            }
        }
    }
    var scale = 1
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var triangles: [Int32] = []

    init (file: String) throws {
        let contents = try String(contentsOfFile: file).replacingOccurrences(of: "\r", with: "")
        let lines = contents.split(separator: "\n")

        for line in lines {
            switch line.first {
            case "#":
                break
            case "v":
                if line.starts(with: "v ") {
                    let p = line.split(separator: " ")
                    if p.count < 4 { throw LoadError.invalidFormat }
                    
                    vertices.append([Float (p[1]) ?? 0, Float (p [2]) ?? 0, Float (p [3]) ?? 0])
                }
            case "f":
                let vertCount = Int32(vertices.count)
                let faceDefs = line.split (whereSeparator: { $0.isWhitespace })
                var face: [Int32] = []
                for faceDef in faceDefs.dropFirst() {
                    let vi: Int32
                    if let idx = faceDef.firstIndex(of: "/") {
                        vi = Int32 (faceDef [faceDef.startIndex..<idx]) ?? 0
                    } else {
                        vi = Int32 (faceDef) ?? 0
                    }
                    face.append(vi < 0 ? vertCount : vi-1)
                }
                if face.count > 2 {
                    let a = face [0]
                    for i in 2..<face.count {
                        let b = face [i-1]
                        let c = face [i]
                        if a < 0 || a >= vertCount || b < 0 || b >= vertCount || c < 0 || c >= vertCount {
                            continue
                        }
                        triangles.append(contentsOf: [a, b, c])
                    }
                }
            case "m" where line.starts(with: "mtllib"):
                break
            case "u" where line.starts(with: "usemtl"):
                break
            case "o", "g":
                break
            default:
                print (line)
                //throw LoadError.unsupportedFeature(String (line))
            }
        }
        
        // calculate normals
        for i in stride(from: 0, to: triangles.count, by: 3) {
            let v0 = triangles [i]
            let v1 = triangles [i+1]
            let v2 = triangles [i+2]
            
            let e0: SIMD3<Float> = vertices [Int (v1)]-vertices [Int(v0)]
            let e1: SIMD3<Float> = vertices [Int (v2)]-vertices [Int(v0)]
            let n: SIMD3<Float> = [e0.y*e1.z - e0.z*e1.y,
                                   e0.z*e1.x - e0.x*e1.z,
                                   e0.x*e1.y - e0.y*e1.x]
            let d = sqrtf(n.x*n.x+n.y*n.y+n.z*n.z)
            if d > 0 {
                let invd = 1/d
                normals.append(n * invd)
            } else {
                normals.append(n)
            }
        }
    }
}

#if false

func testLoader () throws {
    let files = ["undulating.obj", "dungeon.obj", "nav_test.obj" ]
    
    for file in files {
        let data = try ObjMeshLoader(file: "/Users/miguel/cvs/recastnavigation/RecastDemo/Bin/Meshes/\(file)")
        
        do {
            let config = NavMeshBuilder.Config (partitionStyle: .monotone)
            let navMesh = try NavMeshBuilder(vertices: data.vertices, triangles: data.triangles, config: config)
            print ("Navmesh for \(file)")
            let navigator = try navMesh.makeNavMesh(agentHeight: 1, agentRadius: 0.3, agentMaxClimb: 20)
            print (navigator)
        } catch (let e) {
            print ("Error On file \(file): \(e)")
            throw e
        }
    }
}

func testFindPath () throws {
    let data = try ObjMeshLoader(file: "/Users/miguel/cvs/recastnavigation/RecastDemo/Bin/Meshes/dungeon.obj")
    let config = NavMeshBuilder.Config (partitionStyle: .monotone)
    let navMesh = try NavMeshBuilder(vertices: data.vertices, triangles: data.triangles, config: config)
    let navigator = try navMesh.makeNavMesh(agentHeight: 1, agentRadius: 0.3, agentMaxClimb: 20)
    let query = try navigator.makeQuery()
    
    let start = try query.findRandomPoint(randomFunction: fakeRandom).get ()
    let end = try query.findRandomPoint(randomFunction: fakeRandom).get ()
    
    switch query.findPathCorridor(start: start, end: end) {
    case .success(let corridor):
        print ("Found a path from \(start) to \(end)")
        for poly in corridor {
            print ("    PolyRef: \(poly)")
        }
        switch query.findStraightPath(startPos: start.point3, endPos: end.point3, pathCorridor: corridor, options: [.allCrossings, .areaCrossings]) {
        case .success(let found):
            for x in 0..<found.count {
                let pidx = x * 3
                print (" \(x): \(found.path[pidx]), \(found.path[pidx+1]), \(found.path[pidx+2]): \(found.flags[x]) at poly: \(found.polyRefs[x])")
            }
        case .failure (let d):
            print ("Failed calling findStraightPath: \(d)")
        }
    case .failure(let d):
        print ("Failed calling findPathCorridor error, details: \(d)")
    }
}

func testCrowd () throws {
    let data = try ObjMeshLoader(file: "/Users/miguel/cvs/recastnavigation/RecastDemo/Bin/Meshes/dungeon.obj")
    let config = NavMeshBuilder.Config (partitionStyle: .monotone)
    let builder = try NavMeshBuilder(vertices: data.vertices, triangles: data.triangles, config: config)
    let navigator = try builder.makeNavMesh(agentHeight: 1, agentRadius: 0.3, agentMaxClimb: 20)
    let query = try navigator.makeQuery()
    
    let end = try query.findRandomPoint(randomFunction: fakeRandom).get ()
    print ("Target is: \(end)")

    let crowd = try navigator.makeCrowd(maxAgents: 16, agentRadius: 0.3)
    var agents: [CrowdAgent] = []
    for _ in 0..<4 {
        let agentStart = try query.findRandomPoint(randomFunction: fakeRandom).get ()
        guard let agent = crowd.addAgent(agentStart.point3) else { continue }
        agents.append(agent)
        agent.requestMove(target: end)
    }
    for x in stride(from: 0.0, to: 3.0, by: 0.01) {
        crowd.update(dt: Float (x))
        for x in 0..<agents.count {
            print ("\(x): \(agents [x].position)")
        }
    }
}
#endif
