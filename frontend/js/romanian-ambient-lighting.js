/**
 * Romanian Ambient Lighting System
 * Creates authentic Romanian café/card house atmosphere for premium visual experience
 * Inspired by traditional Romanian gathering spaces and cultural authenticity
 */

class RomanianAmbientLighting {
    constructor(scene, renderer) {
        this.scene = scene;
        this.renderer = renderer;
        this.lights = new Map();
        this.shadowConfig = {
            enabled: true,
            mapSize: 2048,
            camera: {
                near: 0.1,
                far: 50,
                fov: 50
            }
        };
        
        // Romanian cultural atmosphere settings
        this.atmosphereConfig = {
            warmth: 0.8,        // Warm café lighting
            intimacy: 0.7,      // Cozy card house feeling
            tradition: 0.9,     // Cultural authenticity
            elegance: 0.6       // Refined but not overly formal
        };
        
        this.timeOfDay = 'evening'; // Default to cozy evening atmosphere
        this.region = 'traditional'; // Romanian regional variation
        
        console.log('🕯️ Romanian Ambient Lighting System initialized');
        this.setupRenderer();
        this.createLightingEnvironment();
    }
    
    /**
     * Configure renderer for optimal lighting
     */
    setupRenderer() {
        // Safety check for renderer
        if (!this.renderer || !this.renderer.shadowMap) {
            console.warn('🕯️ Renderer not available for shadow configuration');
            return;
        }
        
        // Enable shadows for realistic depth
        this.renderer.shadowMap.enabled = this.shadowConfig.enabled;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap; // Soft shadows
        
        // Advanced rendering features
        this.renderer.physicallyCorrectLights = true;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2; // Slightly bright for card visibility
        
        // Romanian warm color temperature
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        
        console.log('🎨 Renderer configured for Romanian café lighting');
    }
    
    /**
     * Create complete Romanian card house lighting environment
     */
    createLightingEnvironment() {
        this.removeAllLights();
        
        // Primary lighting setup based on time and region
        this.createKeyLighting();
        this.createFillLighting();
        this.createRimLighting();
        this.createAmbientLighting();
        
        // Cultural atmospheric elements
        this.addTraditionalElements();
        this.configureShadows();
        
        console.log(`🕯️ Romanian ${this.timeOfDay} lighting environment created`);
    }
    
    /**
     * Create main key lighting - simulates primary light source
     */
    createKeyLighting() {
        const keyLight = new THREE.DirectionalLight();
        
        // Configure based on time of day and cultural setting
        const config = this.getKeyLightConfig();
        keyLight.color.setHex(config.color);
        keyLight.intensity = config.intensity;
        
        // Position for optimal card visibility
        keyLight.position.set(5, 8, 6);
        keyLight.target.position.set(0, 0, 0);
        
        // Shadow configuration
        keyLight.castShadow = true;
        keyLight.shadow.mapSize.width = this.shadowConfig.mapSize;
        keyLight.shadow.mapSize.height = this.shadowConfig.mapSize;
        
        // Shadow camera setup for game table area
        const shadowCamera = keyLight.shadow.camera;
        shadowCamera.near = this.shadowConfig.camera.near;
        shadowCamera.far = this.shadowConfig.camera.far;
        shadowCamera.left = -10;
        shadowCamera.right = 10;
        shadowCamera.top = 10;
        shadowCamera.bottom = -10;
        
        this.scene.add(keyLight);
        this.scene.add(keyLight.target);
        this.lights.set('key', keyLight);
        
        console.log(`🔆 Key light created: ${config.description}`);
    }
    
    /**
     * Get key light configuration based on time and region
     */
    getKeyLightConfig() {
        const configs = {
            morning: {
                color: 0xfff4e6,  // Warm morning sunlight
                intensity: 0.7,
                description: 'Morning sunlight through café windows'
            },
            afternoon: {
                color: 0xfffacd,  // Soft afternoon light
                intensity: 0.6,
                description: 'Gentle afternoon café ambiance'
            },
            evening: {
                color: 0xffd700,  // Warm golden hour
                intensity: 0.5,
                description: 'Golden hour café warmth'
            },
            night: {
                color: 0xffb347,  // Warm artificial lighting
                intensity: 0.4,
                description: 'Cozy nighttime card house lighting'
            }
        };
        
        return configs[this.timeOfDay] || configs.evening;
    }
    
    /**
     * Create fill lighting to soften shadows
     */
    createFillLighting() {
        const fillLight = new THREE.DirectionalLight();
        
        // Soft fill light opposite to key light
        fillLight.color.setHex(0xfff8dc); // Warm white
        fillLight.intensity = 0.3;
        fillLight.position.set(-3, 4, -2);
        fillLight.target.position.set(0, 0, 0);
        
        // No shadows for fill light
        fillLight.castShadow = false;
        
        this.scene.add(fillLight);
        this.scene.add(fillLight.target);
        this.lights.set('fill', fillLight);
        
        console.log('💡 Fill lighting added for shadow softening');
    }
    
    /**
     * Create rim lighting for card edge definition
     */
    createRimLighting() {
        const rimLight = new THREE.DirectionalLight();
        
        // Subtle rim light with Romanian cultural touch
        rimLight.color.setHex(0x7c4dff); // Subtle purple rim (Romanian folk accent)
        rimLight.intensity = 0.15;
        rimLight.position.set(-6, 2, 8);
        rimLight.target.position.set(0, 0, 0);
        
        // No shadows for rim light
        rimLight.castShadow = false;
        
        this.scene.add(rimLight);
        this.scene.add(rimLight.target);
        this.lights.set('rim', rimLight);
        
        console.log('✨ Rim lighting added for card edge definition');
    }
    
    /**
     * Create ambient lighting for general scene illumination
     */
    createAmbientLighting() {
        const ambientLight = new THREE.AmbientLight();
        
        // Romanian café ambient color and intensity
        ambientLight.color.setHex(0xfff8dc); // Warm cream color
        ambientLight.intensity = 0.4 * this.atmosphereConfig.warmth;
        
        this.scene.add(ambientLight);
        this.lights.set('ambient', ambientLight);
        
        console.log('🌅 Ambient lighting added for Romanian café atmosphere');
    }
    
    /**
     * Add traditional Romanian atmospheric elements
     */
    addTraditionalElements() {
        // Simulated candle light for traditional atmosphere
        if (this.atmosphereConfig.tradition > 0.8) {
            this.addCandleLight();
        }
        
        // Fireplace glow for cozy winter evening feel
        if (this.timeOfDay === 'night' && this.region === 'carpathian') {
            this.addFireplaceGlow();
        }
        
        // Window light simulation for daytime
        if (this.timeOfDay === 'morning' || this.timeOfDay === 'afternoon') {
            this.addWindowLight();
        }
    }
    
    /**
     * Add simulated candle lighting for traditional Romanian atmosphere
     */
    addCandleLight() {
        const candleLight = new THREE.PointLight();
        
        candleLight.color.setHex(0xffaa44); // Warm candle flame color
        candleLight.intensity = 0.2;
        candleLight.distance = 8;
        candleLight.decay = 2;
        
        // Position on side of table
        candleLight.position.set(4, 3, 0);
        
        // Subtle shadow casting
        candleLight.castShadow = true;
        candleLight.shadow.mapSize.width = 512;
        candleLight.shadow.mapSize.height = 512;
        candleLight.shadow.camera.near = 0.1;
        candleLight.shadow.camera.far = 10;
        
        this.scene.add(candleLight);
        this.lights.set('candle', candleLight);
        
        // Add flickering animation
        this.animateCandleFlicker(candleLight);
        
        console.log('🕯️ Traditional candle lighting added');
    }
    
    /**
     * Add fireplace glow for Carpathian mountain atmosphere
     */
    addFireplaceGlow() {
        const fireplaceLight = new THREE.PointLight();
        
        fireplaceLight.color.setHex(0xff6600); // Warm orange firelight
        fireplaceLight.intensity = 0.3;
        fireplaceLight.distance = 12;
        fireplaceLight.decay = 1.5;
        
        // Position to simulate fireplace on the side
        fireplaceLight.position.set(-8, 2, -2);
        
        this.scene.add(fireplaceLight);
        this.lights.set('fireplace', fireplaceLight);
        
        // Add gentle flickering
        this.animateFireplaceFlicker(fireplaceLight);
        
        console.log('🔥 Carpathian fireplace glow added');
    }
    
    /**
     * Add window light simulation for daytime
     */
    addWindowLight() {
        const windowLight = new THREE.RectAreaLight();
        
        windowLight.color.setHex(0xffffff); // Natural daylight
        windowLight.intensity = 0.3;
        windowLight.width = 4;
        windowLight.height = 6;
        
        // Position as if coming through window
        windowLight.position.set(-6, 4, 8);
        windowLight.lookAt(0, 0, 0);
        
        this.scene.add(windowLight);
        this.lights.set('window', windowLight);
        
        console.log('🪟 Natural window lighting added');
    }
    
    /**
     * Configure shadow settings for optimal card game visibility
     */
    configureShadows() {
        const keyLight = this.lights.get('key');
        if (keyLight && keyLight.castShadow) {
            // Optimize shadow bias to prevent shadow acne
            keyLight.shadow.bias = -0.0005;
            keyLight.shadow.normalBias = 0.02;
            
            // Shadow softness for realistic appearance
            keyLight.shadow.radius = 4;
            keyLight.shadow.blurSamples = 15;
        }
        
        console.log('🌑 Shadow configuration optimized for card visibility');
    }
    
    /**
     * Animate candle flickering for traditional atmosphere
     */
    animateCandleFlicker(candleLight) {
        let flickerPhase = 0;
        const baseIntensity = candleLight.intensity;
        
        const flicker = () => {
            flickerPhase += 0.1;
            const flickerAmount = Math.sin(flickerPhase) * 0.02 + Math.random() * 0.01;
            candleLight.intensity = baseIntensity + flickerAmount;
            
            requestAnimationFrame(flicker);
        };
        
        flicker();
    }
    
    /**
     * Animate fireplace flickering
     */
    animateFireplaceFlicker(fireplaceLight) {
        let flickerPhase = 0;
        const baseIntensity = fireplaceLight.intensity;
        
        const flicker = () => {
            flickerPhase += 0.05;
            const flickerAmount = Math.sin(flickerPhase * 2) * 0.03 + Math.random() * 0.02;
            fireplaceLight.intensity = baseIntensity + flickerAmount;
            
            requestAnimationFrame(flicker);
        };
        
        flicker();
    }
    
    /**
     * Update lighting based on time of day
     */
    setTimeOfDay(timeOfDay) {
        if (this.timeOfDay !== timeOfDay) {
            this.timeOfDay = timeOfDay;
            this.createLightingEnvironment();
            console.log(`🕯️ Lighting updated to ${timeOfDay} atmosphere`);
        }
    }
    
    /**
     * Update lighting based on Romanian region
     */
    setRegion(region) {
        if (this.region !== region) {
            this.region = region;
            this.createLightingEnvironment();
            console.log(`🏔️ Lighting updated to ${region} regional style`);
        }
    }
    
    /**
     * Adjust atmosphere for different moods
     */
    setAtmosphere(config) {
        Object.assign(this.atmosphereConfig, config);
        this.createLightingEnvironment();
        console.log('🎭 Atmosphere configuration updated');
    }
    
    /**
     * Optimize lighting for performance level
     */
    updateLOD(qualityLevel) {
        switch (qualityLevel) {
            case 'ultra':
                this.shadowConfig.mapSize = 2048;
                this.enableAllLights();
                break;
                
            case 'high':
                this.shadowConfig.mapSize = 1024;
                this.enableAllLights();
                break;
                
            case 'medium':
                this.shadowConfig.mapSize = 512;
                this.disableSecondaryLights();
                break;
                
            case 'low':
                this.shadowConfig.mapSize = 256;
                this.disableShadows();
                this.disableSecondaryLights();
                break;
        }
        
        this.createLightingEnvironment();
        console.log(`🎨 Lighting optimized for ${qualityLevel} quality`);
    }
    
    /**
     * Enable all lighting effects
     */
    enableAllLights() {
        this.lights.forEach(light => {
            light.visible = true;
        });
    }
    
    /**
     * Disable secondary atmospheric lights
     */
    disableSecondaryLights() {
        const secondaryLights = ['candle', 'fireplace', 'window'];
        secondaryLights.forEach(lightName => {
            const light = this.lights.get(lightName);
            if (light) light.visible = false;
        });
    }
    
    /**
     * Disable shadows for performance
     */
    disableShadows() {
        this.lights.forEach(light => {
            if (light.castShadow) {
                light.castShadow = false;
            }
        });
        this.renderer.shadowMap.enabled = false;
    }
    
    /**
     * Remove all lights from scene
     */
    removeAllLights() {
        this.lights.forEach(light => {
            this.scene.remove(light);
            if (light.target) this.scene.remove(light.target);
        });
        this.lights.clear();
    }
    
    /**
     * Get current lighting statistics
     */
    getLightingStats() {
        return {
            lightCount: this.lights.size,
            shadowsEnabled: this.shadowConfig.enabled,
            shadowMapSize: this.shadowConfig.mapSize,
            timeOfDay: this.timeOfDay,
            region: this.region,
            atmosphere: this.atmosphereConfig
        };
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        this.removeAllLights();
        console.log('🕯️ Romanian Ambient Lighting System disposed');
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RomanianAmbientLighting;
} else if (typeof window !== 'undefined') {
    window.RomanianAmbientLighting = RomanianAmbientLighting;
}