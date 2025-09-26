const DEG2RAD = Math.PI / 180;

export function fanLayout(count, {
  radius = 3.2,
  maxAngle = 50,
  lift = 0.15,
  tilt = -8,
  facing = 0
} = {}) {
  if (count <= 0) return [];
  const arc = maxAngle * DEG2RAD;
  const tiltRad = tilt * DEG2RAD;
  const facingRad = facing * DEG2RAD;
  const poses = [];

  for (let i = 0; i < count; i++) {
    const t = count === 1 ? 0 : i / (count - 1); // 0..1
    const normalized = count === 1 ? 0 : t - 0.5; // centered range
    const angle = normalized * arc;
    const x = Math.sin(angle) * radius;
    const z = radius - Math.cos(angle) * radius;
    const height = lift * (1 - Math.abs(normalized) * 1.6);
    poses.push({
      position: { x, y: height, z },
      rotation: { x: tiltRad, y: facingRad + angle, z: 0 }
    });
  }

  return poses;
}
