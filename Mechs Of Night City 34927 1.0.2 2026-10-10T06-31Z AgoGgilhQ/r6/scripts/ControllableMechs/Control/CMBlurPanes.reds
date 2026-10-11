module ControllableMechs.Control

import ControllableMechs.*

public class CMBlurPanes {
  private let m_panes: array<wref<MeshComponent>>;
  private let m_rects: array<Vector4>;
  private let m_fov0: Float;
  private let m_fov: Float;
  private let m_used: Int32;

  public static func Count() -> Int32 = 16
  public static func Template() -> ResRef = r"mnc\\ui\\blur_camera.ent"

  private func D0() -> Float = 0.35

  public static func Look(i: Int32) -> CName {
    switch i {
      case 2: return n"b";
      case 3: return n"c";
      case 4: return n"d";
      default: return n"default";
    }
  }

  public func Setup(cam: ref<Entity>, rects: array<Vector4>, fov: Float, look: Int32) -> Void {
    ArrayClear(this.m_panes);
    this.m_rects = rects;
    this.m_fov0 = fov;
    this.m_used = 0;
    let i = 0;
    while i < CMBlurPanes.Count() {
      let m = cam.FindComponentByName(StringToName("blur" + IntToString(i))) as MeshComponent;
      if IsDefined(m) {
        ArrayPush(this.m_panes, m);
      }
      i += 1;
    }
    if ArraySize(this.m_panes) == 0 {
      return;
    }
    let t = this.D0() * TanF(Deg2Rad(fov * 0.5)) / 1080.0;
    this.m_fov = fov;
    i = 0;
    while i < ArraySize(this.m_panes) {
      let m = this.m_panes[i];
      if i < ArraySize(rects) {
        let r = rects[i];
        m.visualScale = new Vector3((r.Z - r.X) * t / 10.0, (r.W - r.Y) * t / 10.0, 1.0);
        m.ChangeAppearance(CMBlurPanes.Look(look));
        m.Toggle(true);
        this.m_used += 1;
      } else {
        m.Toggle(false);
      }
      i += 1;
    }
  }

  private func Place(r: Vector4, fov: Float) -> Vector4 {
    let d = this.D0() * TanF(Deg2Rad(this.m_fov0 * 0.5)) / TanF(Deg2Rad(fov * 0.5));
    let t = d * TanF(Deg2Rad(fov * 0.5)) / 1080.0;
    return new Vector4((r.X + r.Z) * 0.5 * t, d, -(r.Y + r.W) * 0.5 * t, 0.0);
  }

  public func Fov(fov: Float) -> Void {
    this.m_fov = fov;
  }

  public func Follow(camPos: Vector4, camRot: Quaternion) -> Void {

    let face: Quaternion;
    face.i = 0.70710678;
    face.r = 0.70710678;
    let q = CMFlight.QMul(camRot, face);
    let i = 0;
    while i < this.m_used {
      let m = this.m_panes[i];
      if IsDefined(m) {
        let p = camPos + CMFlight.QRot(camRot, this.Place(this.m_rects[i], this.m_fov));
        p.W = 0.0;
        m.SetLocalPosition(p);
        m.SetLocalOrientation(q);
      }
      i += 1;
    }
  }
}
