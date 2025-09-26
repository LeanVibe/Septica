import assert from 'node:assert/strict';
import { fanLayout } from '../src/utils/fan-layout.js';

const almostEqual = (a, b, tol = 1e-6) => Math.abs(a - b) < tol;

// Basic test: single card centers at origin
{
  const poses = fanLayout(1);
  assert.equal(poses.length, 1);
  assert(almostEqual(poses[0].position.x, 0));
  assert(almostEqual(poses[0].position.z, 0));
  assert(almostEqual(poses[0].rotation.y, 0));
}

// Symmetry test for three cards
{
  const poses = fanLayout(3, { maxAngle: 60, radius: 3 });
  assert.equal(poses.length, 3);
  const left = poses[0];
  const middle = poses[1];
  const right = poses[2];

  assert(almostEqual(left.position.x, -right.position.x));
  assert(almostEqual(left.position.z, right.position.z));
  assert(almostEqual(left.rotation.y, -right.rotation.y));
  assert(almostEqual(middle.position.x, 0));
  assert(almostEqual(middle.rotation.y, 0));
}

console.log('fan-layout tests passed');
