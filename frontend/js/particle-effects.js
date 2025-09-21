/**
 * Particle Effects System for Romanian Septica
 * Special effects for game moves and celebrations
 */

class ParticleEffectsSystem {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.options = {
            maxParticles: options.maxParticles || 100,
            particleSize: options.particleSize || 0.05,
            gravity: options.gravity || -0.98,
            enablePhysics: options.enablePhysics !== false,
            qualityLevel: options.qualityLevel || 'high',
            ...options
        };
        
        this.particleSystems = [];
        this.activeEffects = new Map();
        this.effectTemplates = this.createEffectTemplates();
        
        // Performance settings based on quality level
        this.qualitySettings = {
            high: { maxParticles: 100, particleSize: 0.05, updateRate: 60 },
            medium: { maxParticles: 50, particleSize: 0.07, updateRate: 30 },
            low: { maxParticles: 20, particleSize: 0.1, updateRate: 15 }
        };
        
        this.currentSettings = this.qualitySettings[this.options.qualityLevel];
        this.lastUpdate = performance.now();
        this.updateInterval = 1000 / this.currentSettings.updateRate;
        
        this.initializeParticlePools();
    }
    
    /**
     * Create effect templates for different Romanian Septica moves
     */
    createEffectTemplates() {
        return {
            // When a 7 beats other cards (major Romanian Septica rule)
            sevenBeats: {
                particleCount: 30,
                colors: [0xFCD116, 0x002B7F, 0xCE1126], // Romanian flag colors
                lifetime: 2000,
                speed: 2,
                spread: Math.PI / 3,
                shape: 'burst',
                gravity: true
            },
            
            // When capturing multiple cards
            cardCapture: {
                particleCount: 20,
                colors: [0xFFD700, 0xFFA500],
                lifetime: 1500,
                speed: 1.5,
                spread: Math.PI / 4,
                shape: 'fountain',
                gravity: true
            },
            
            // Trick win celebration
            trickWin: {
                particleCount: 25,
                colors: [0x00FF00, 0x32CD32, 0x90EE90],
                lifetime: 2500,
                speed: 1.8,
                spread: Math.PI / 2,
                shape: 'explosion',
                gravity: false
            },
            
            // Game win celebration
            gameWin: {
                particleCount: 50,
                colors: [0xFFD700, 0xFFC107, 0xFFE082],
                lifetime: 3000,
                speed: 2.5,
                spread: Math.PI,
                shape: 'fireworks',
                gravity: false
            },
            
            // Card selection sparkle
            cardSelect: {
                particleCount: 8,
                colors: [0x87CEEB, 0x4169E1],
                lifetime: 800,
                speed: 0.8,
                spread: Math.PI / 6,
                shape: 'sparkle',
                gravity: false
            },
            
            // Invalid move warning
            invalidMove: {
                particleCount: 15,
                colors: [0xFF4444, 0xFF6B6B],
                lifetime: 1000,
                speed: 1.2,
                spread: Math.PI / 8,
                shape: 'warning',
                gravity: true
            }
        };
    }
    
    /**
     * Initialize particle object pools for performance
     */
    initializeParticlePools() {
        this.particlePool = [];
        this.particleGeometry = new THREE.SphereGeometry(this.currentSettings.particleSize, 6, 4);
        
        // Create materials for different particle types
        this.particleMaterials = {
            default: new THREE.MeshBasicMaterial({ 
                transparent: true, 
                opacity: 0.8 
            }),
            sparkle: new THREE.MeshBasicMaterial({ 
                transparent: true, 
                opacity: 1.0,
                emissive: 0x444444
            }),
            glow: new THREE.MeshBasicMaterial({ 
                transparent: true, 
                opacity: 0.9,
                emissive: 0x222222
            })
        };
        
        // Pre-create particle pool
        for (let i = 0; i < this.currentSettings.maxParticles; i++) {
            const particle = new THREE.Mesh(this.particleGeometry, this.particleMaterials.default.clone());
            particle.visible = false;
            particle.userData = {
                velocity: new THREE.Vector3(),
                age: 0,
                lifetime: 1000,
                initialSize: this.currentSettings.particleSize,
                active: false
            };
            this.particlePool.push(particle);
            this.scene.add(particle);
        }
    }
    
    /**
     * Trigger a particle effect
     */
    triggerEffect(effectType, position, options = {}) {
        const template = this.effectTemplates[effectType];
        if (!template) {
            console.warn(`Unknown particle effect: ${effectType}`);
            return;
        }
        
        const effect = {
            id: `${effectType}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            type: effectType,
            position: position.clone ? position.clone() : new THREE.Vector3(position.x, position.y, position.z),
            template: { ...template, ...options },
            particles: [],
            startTime: performance.now(),
            active: true
        };
        
        this.createEffectParticles(effect);
        this.activeEffects.set(effect.id, effect);
        
        console.log(`Triggered ${effectType} effect at`, position);
        return effect.id;
    }
    
    /**
     * Create particles for an effect
     */
    createEffectParticles(effect) {
        const { template, position } = effect;
        const particleCount = Math.min(template.particleCount, this.currentSettings.maxParticles);
        
        for (let i = 0; i < particleCount; i++) {
            const particle = this.getParticleFromPool();
            if (!particle) break;
            
            // Set particle properties
            particle.position.copy(position);
            particle.userData.active = true;
            particle.userData.age = 0;
            particle.userData.lifetime = template.lifetime + (Math.random() - 0.5) * 200;
            particle.visible = true;
            
            // Set color
            const colorIndex = Math.floor(Math.random() * template.colors.length);
            particle.material.color.setHex(template.colors[colorIndex]);
            
            // Set initial velocity based on effect shape
            this.setParticleVelocity(particle, template, i, particleCount);
            
            effect.particles.push(particle);
        }
    }
    
    /**
     * Set particle velocity based on effect shape
     */
    setParticleVelocity(particle, template, index, totalParticles) {
        const velocity = particle.userData.velocity;
        const speed = template.speed * (0.5 + Math.random() * 0.5);
        
        switch (template.shape) {
            case 'burst':
                const burstAngle = (index / totalParticles) * Math.PI * 2;
                velocity.set(
                    Math.cos(burstAngle) * speed,
                    Math.random() * speed * 0.5,
                    Math.sin(burstAngle) * speed
                );
                break;
                
            case 'fountain':
                const fountainSpread = template.spread;
                const angle = (Math.random() - 0.5) * fountainSpread;
                velocity.set(
                    Math.sin(angle) * speed,
                    speed * (0.8 + Math.random() * 0.4),
                    Math.cos(angle) * speed * 0.3
                );
                break;
                
            case 'explosion':
                velocity.set(
                    (Math.random() - 0.5) * speed * 2,
                    (Math.random() - 0.5) * speed * 2,
                    (Math.random() - 0.5) * speed * 2
                );
                break;
                
            case 'fireworks':
                const fireworkAngle = Math.random() * Math.PI * 2;
                const fireworkElevation = Math.random() * Math.PI / 3;
                velocity.set(
                    Math.cos(fireworkAngle) * Math.cos(fireworkElevation) * speed,
                    Math.sin(fireworkElevation) * speed,
                    Math.sin(fireworkAngle) * Math.cos(fireworkElevation) * speed
                );
                break;
                
            case 'sparkle':
                velocity.set(
                    (Math.random() - 0.5) * speed * 0.5,
                    Math.random() * speed * 0.3,
                    (Math.random() - 0.5) * speed * 0.5
                );
                break;
                
            case 'warning':
                velocity.set(
                    (Math.random() - 0.5) * speed,
                    speed * 0.5,
                    (Math.random() - 0.5) * speed * 0.3
                );
                break;
                
            default:
                velocity.set(
                    (Math.random() - 0.5) * speed,
                    Math.random() * speed,
                    (Math.random() - 0.5) * speed
                );
        }
    }
    
    /**
     * Get an available particle from the pool
     */
    getParticleFromPool() {
        for (const particle of this.particlePool) {
            if (!particle.userData.active) {
                return particle;
            }
        }
        return null;
    }
    
    /**
     * Return particle to pool
     */
    returnParticleToPool(particle) {
        particle.userData.active = false;
        particle.visible = false;
        particle.userData.age = 0;
        particle.scale.set(1, 1, 1);
        particle.material.opacity = this.particleMaterials.default.opacity;
    }
    
    /**
     * Update all active particle effects
     */
    update() {
        const now = performance.now();
        const deltaTime = now - this.lastUpdate;
        
        // Limit update rate for performance
        if (deltaTime < this.updateInterval) {
            return;
        }
        
        this.lastUpdate = now;
        const dt = deltaTime / 1000; // Convert to seconds
        
        // Update each active effect
        for (const [effectId, effect] of this.activeEffects) {
            this.updateEffect(effect, dt);
            
            // Remove completed effects
            if (!effect.active) {
                this.activeEffects.delete(effectId);
            }
        }
    }
    
    /**
     * Update a single particle effect
     */
    updateEffect(effect, deltaTime) {
        let activeParticles = 0;
        
        for (const particle of effect.particles) {
            if (!particle.userData.active) continue;
            
            // Update particle age
            particle.userData.age += deltaTime * 1000;
            
            // Check if particle should die
            if (particle.userData.age >= particle.userData.lifetime) {
                this.returnParticleToPool(particle);
                continue;
            }
            
            activeParticles++;
            
            // Update particle position
            const velocity = particle.userData.velocity;
            particle.position.x += velocity.x * deltaTime;
            particle.position.y += velocity.y * deltaTime;
            particle.position.z += velocity.z * deltaTime;
            
            // Apply gravity if enabled
            if (effect.template.gravity && this.options.enablePhysics) {
                velocity.y += this.options.gravity * deltaTime;
            }
            
            // Apply drag
            velocity.multiplyScalar(0.98);
            
            // Update particle appearance based on age
            const ageRatio = particle.userData.age / particle.userData.lifetime;
            
            // Fade out over time
            particle.material.opacity = (1 - ageRatio) * 0.8;
            
            // Scale particle based on effect type
            if (effect.type === 'sparkle') {
                const scale = 1 + Math.sin(ageRatio * Math.PI * 4) * 0.3;
                particle.scale.set(scale, scale, scale);
            } else {
                const scale = 1 - ageRatio * 0.5;
                particle.scale.set(scale, scale, scale);
            }
        }
        
        // Mark effect as inactive if no particles remain
        if (activeParticles === 0) {
            effect.active = false;
            effect.particles.length = 0;
        }
    }
    
    /**
     * Trigger effect for Romanian Septica specific moves
     */
    triggerSevenBeats(position) {
        return this.triggerEffect('sevenBeats', position);
    }
    
    triggerCardCapture(position, cardCount = 1) {
        const intensity = Math.min(cardCount / 5, 1); // Scale effect with captured cards
        return this.triggerEffect('cardCapture', position, {
            particleCount: Math.round(20 * intensity),
            speed: 1.5 + intensity * 0.5
        });
    }
    
    triggerTrickWin(position) {
        return this.triggerEffect('trickWin', position);
    }
    
    triggerGameWin(position) {
        return this.triggerEffect('gameWin', position);
    }
    
    triggerCardSelect(position) {
        return this.triggerEffect('cardSelect', position);
    }
    
    triggerInvalidMove(position) {
        return this.triggerEffect('invalidMove', position);
    }
    
    /**
     * Stop a specific effect
     */
    stopEffect(effectId) {
        const effect = this.activeEffects.get(effectId);
        if (effect) {
            // Return all particles to pool
            for (const particle of effect.particles) {
                this.returnParticleToPool(particle);
            }
            effect.active = false;
            this.activeEffects.delete(effectId);
        }
    }
    
    /**
     * Stop all effects
     */
    stopAllEffects() {
        for (const [effectId] of this.activeEffects) {
            this.stopEffect(effectId);
        }
    }
    
    /**
     * Update quality level and performance settings
     */
    setQualityLevel(qualityLevel) {
        this.options.qualityLevel = qualityLevel;
        this.currentSettings = this.qualitySettings[qualityLevel];
        this.updateInterval = 1000 / this.currentSettings.updateRate;
        
        // Update particle size
        if (this.particleGeometry) {
            this.particleGeometry.dispose();
            this.particleGeometry = new THREE.SphereGeometry(this.currentSettings.particleSize, 6, 4);
            
            // Update existing particles
            for (const particle of this.particlePool) {
                particle.geometry = this.particleGeometry;
            }
        }
        
        console.log(`Particle effects quality set to ${qualityLevel}`);
    }
    
    /**
     * Get performance statistics
     */
    getStats() {
        let activeParticleCount = 0;
        for (const particle of this.particlePool) {
            if (particle.userData.active) {
                activeParticleCount++;
            }
        }
        
        return {
            activeEffects: this.activeEffects.size,
            activeParticles: activeParticleCount,
            totalParticles: this.particlePool.length,
            qualityLevel: this.options.qualityLevel,
            updateRate: this.currentSettings.updateRate
        };
    }
    
    /**
     * Cleanup resources
     */
    dispose() {
        this.stopAllEffects();
        
        // Dispose geometry and materials
        if (this.particleGeometry) {
            this.particleGeometry.dispose();
        }
        
        for (const material of Object.values(this.particleMaterials)) {
            material.dispose();
        }
        
        // Remove particles from scene
        for (const particle of this.particlePool) {
            this.scene.remove(particle);
        }
        
        this.particlePool.length = 0;
        this.activeEffects.clear();
    }
}

// Export for global use
window.ParticleEffectsSystem = ParticleEffectsSystem;