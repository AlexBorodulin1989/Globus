/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

// Math Library v3.02

// swiftlint:disable type_name
// swiftlint:disable identifier_name
// swiftlint:disable comma

import simd
import CoreGraphics

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

typealias double2 = SIMD2<Double>
typealias double3 = SIMD3<Double>
typealias double4 = SIMD4<Double>

let π = Float.pi

extension Float {
  var radiansToDegrees: Float {
    (self / π) * 180
  }
  var degreesToRadians: Float {
    (self / 180) * π
  }
}

extension Double {
  var radiansToDegrees: Double {
      (self / Double.pi) * 180
  }
  var degreesToRadians: Double {
      (self / 180) * Double.pi
  }
}

// MARK: - float4
extension float4x4 {
  // MARK: - Translate
  init(translation: float3) {
    let matrix = float4x4(
      [            1,             0,             0, 0],
      [            0,             1,             0, 0],
      [            0,             0,             1, 0],
      [translation.x, translation.y, translation.z, 1]
    )
    self = matrix
  }

  // MARK: - Scale
  init(scaling: float3) {
    let matrix = float4x4(
      [scaling.x,         0,         0, 0],
      [        0, scaling.y,         0, 0],
      [        0,         0, scaling.z, 0],
      [        0,         0,         0, 1]
    )
    self = matrix
  }

  init(scaling: Float) {
    self = matrix_identity_float4x4
    columns.3.w = 1 / scaling
  }

  // MARK: - Rotate
  init(rotationX angle: Float) {
    let matrix = float4x4(
      [1,           0,          0, 0],
      [0,  cos(angle), sin(angle), 0],
      [0, -sin(angle), cos(angle), 0],
      [0,           0,          0, 1]
    )
    self = matrix
  }

  init(rotationY angle: Float) {
    let matrix = float4x4(
      [cos(angle), 0, -sin(angle), 0],
      [         0, 1,           0, 0],
      [sin(angle), 0,  cos(angle), 0],
      [         0, 0,           0, 1]
    )
    self = matrix
  }

  init(rotationZ angle: Float) {
    let matrix = float4x4(
      [ cos(angle), sin(angle), 0, 0],
      [-sin(angle), cos(angle), 0, 0],
      [          0,          0, 1, 0],
      [          0,          0, 0, 1]
    )
    self = matrix
  }

  init(rotation angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationX * rotationY * rotationZ
  }

  init(rotationYXZ angle: float3) {
    let rotationX = float4x4(rotationX: angle.x)
    let rotationY = float4x4(rotationY: angle.y)
    let rotationZ = float4x4(rotationZ: angle.z)
    self = rotationY * rotationX * rotationZ
  }

  // MARK: - Identity
  static var identity: float4x4 {
    matrix_identity_float4x4
  }

  // MARK: - Upper left 3x3
  var upperLeft: float3x3 {
    let x = columns.0.xyz
    let y = columns.1.xyz
    let z = columns.2.xyz
    return float3x3(columns: (x, y, z))
  }

  // MARK: - Left handed projection matrix
  init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
    let y = 1 / tan(fov * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    let X = float4( x,  0,  0,  0)
    let Y = float4( 0,  y,  0,  0)
    let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
    let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
    self.init()
    columns = (X, Y, Z, W)
  }

  // left-handed LookAt
  init(eye: float3, center: float3, up: float3) {
    let z = normalize(center - eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)

    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)

    self.init()
    columns = (X, Y, Z, W)
  }

  // MARK: - Orthographic matrix
  init(orthographic rect: CGRect, near: Float, far: Float) {
    let left = Float(rect.origin.x)
    let right = Float(rect.origin.x + rect.width)
    let top = Float(rect.origin.y)
    let bottom = Float(rect.origin.y - rect.height)
    let X = float4(2 / (right - left), 0, 0, 0)
    let Y = float4(0, 2 / (top - bottom), 0, 0)
    let Z = float4(0, 0, 1 / (far - near), 0)
    let W = float4(
      (left + right) / (left - right),
      (top + bottom) / (bottom - top),
      near / (near - far),
      1)
    self.init()
    columns = (X, Y, Z, W)
  }

  // convert double4x4 to float4x4
  init(_ m: matrix_double4x4) {
    self.init()
    let matrix = float4x4(
      float4(m.columns.0),
      float4(m.columns.1),
      float4(m.columns.2),
      float4(m.columns.3))
    self = matrix
  }
}

// MARK: - double4x4
extension double4x4 {
    // MARK: - Translate
    init(translation: double3) {
      let matrix = double4x4(
        [            1,             0,             0, 0],
        [            0,             1,             0, 0],
        [            0,             0,             1, 0],
        [translation.x, translation.y, translation.z, 1]
      )
      self = matrix
    }

    // MARK: - Scale
    init(scaling: double3) {
      let matrix = double4x4(
        [scaling.x,         0,         0, 0],
        [        0, scaling.y,         0, 0],
        [        0,         0, scaling.z, 0],
        [        0,         0,         0, 1]
      )
      self = matrix
    }

    // MARK: - Rotate
    init(rotationX angle: Double) {
      let matrix = double4x4(
        [1,           0,          0, 0],
        [0,  cos(angle), sin(angle), 0],
        [0, -sin(angle), cos(angle), 0],
        [0,           0,          0, 1]
      )
      self = matrix
    }

    init(rotationY angle: Double) {
      let matrix = double4x4(
        [cos(angle), 0, -sin(angle), 0],
        [         0, 1,           0, 0],
        [sin(angle), 0,  cos(angle), 0],
        [         0, 0,           0, 1]
      )
      self = matrix
    }

    init(rotationZ angle: Double) {
      let matrix = double4x4(
        [ cos(angle), sin(angle), 0, 0],
        [-sin(angle), cos(angle), 0, 0],
        [          0,          0, 1, 0],
        [          0,          0, 0, 1]
      )
      self = matrix
    }

    init(rotation angle: double3) {
      let rotationX = double4x4(rotationX: angle.x)
      let rotationY = double4x4(rotationY: angle.y)
      let rotationZ = double4x4(rotationZ: angle.z)
      self = rotationX * rotationY * rotationZ
    }
}

// MARK: - float3x3
extension float3x3 {
  init(normalFrom4x4 matrix: float4x4) {
    self.init()
    columns = matrix.upperLeft.inverse.transpose.columns
  }
}

// MARK: - float4
extension float4 {
  var xyz: float3 {
    get {
      float3(x, y, z)
    }
    set {
      x = newValue.x
      y = newValue.y
      z = newValue.z
    }
  }

  // convert from double4
  init(_ d: SIMD4<Double>) {
    self.init()
    self = [Float(d.x), Float(d.y), Float(d.z), Float(d.w)]
  }
}

// MARK: - float3
extension float3 {
    func normalized() -> float3 {
        let mag = self.magnitude()
        return [x/mag, y/mag, z/mag]
    }

    func magnitude() -> Float {
        return sqrtf(x*x + y*y + z*z);
    }
}
