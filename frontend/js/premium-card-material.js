/**
 * Premium Card Material System
 * Implements ShuffleCats-quality visual rendering with Romanian cultural authenticity
 * Builds on existing Card3DRenderer infrastructure
 */

class PremiumCardMaterial {
    constructor() {
        this.materials = new Map();
        this.textures = new Map();
        this.romanianColors = this.initializeRomanianColorPalette();
        this.culturalPatterns = this.initializeCulturalPatterns();
        
        // Performance optimization
        this.materialCache = new Map();
        this.textureLoader = new THREE.TextureLoader();
        
        console.log('🎨 Premium Card Material System initialized with Romanian cultural elements');
    }
    
    /**
     * Initialize authentic Romanian color palette
     */
    initializeRomanianColorPalette() {
        return {
            // Romanian flag colors with premium gradients
            blue: new THREE.Color(0x002b7f),      // Romanian flag blue
            yellow: new THREE.Color(0xfcd34d),    // Romanian flag yellow  
            red: new THREE.Color(0xdc2626),       // Romanian flag red
            
            // Traditional Romanian folk colors
            burgundy: new THREE.Color(0x800020),  // Traditional Romanian burgundy
            gold: new THREE.Color(0xffd700),      // Traditional gold
            ivory: new THREE.Color(0xfffff0),     // Ivory white
            forestGreen: new THREE.Color(0x1b5e20), // Carpathian forest green
            
            // Premium card colors
            cardWhite: new THREE.Color(0xfafafa),
            cardCream: new THREE.Color(0xfdf6e3),
            shadowGray: new THREE.Color(0x37474f)
        };
    }
    
    /**
     * Initialize Romanian cultural pattern data
     */
    initializeCulturalPatterns() {
        return {
            // Traditional Romanian geometric patterns (SVG data)
            moldovanBorder: `data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz4KICAgIDxwYXR0ZXJuIGlkPSJtb2xkb3ZhbiIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIj4KICAgICAgPHJlY3Qgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjZmNkMzRkIi8+CiAgICAgIDxjaXJjbGUgY3g9IjEwIiBjeT0iMTAiIHI9IjMiIGZpbGw9IiMwMDJiN2YiLz4KICAgIDwvcGF0dGVybj4KICA8L2RlZnM+CiAgPHJlY3Qgd2lkdGg9IjEwMCIgaGVpZ2h0PSIxMDAiIGZpbGw9InVybCgjbW9sZG92YW4pIi8+Cjwvc3ZnPg==`,
            
            transylvanianMotif: `data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz4KICAgIDxwYXR0ZXJuIGlkPSJ0cmFuc3lsdmFuaWFuIiBwYXR0ZXJuVW5pdHM9InVzZXJTcGFjZU9uVXNlIiB3aWR0aD0iMjQiIGhlaWdodD0iMjQiPgogICAgICA8cmVjdCB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIGZpbGw9IiNkYzI2MjYiLz4KICAgICAgPHBvbHlnb24gcG9pbnRzPSIxMiwyIDIyLDEyIDEyLDIyIDIsMTIiIGZpbGw9IiNmZmQ3MDAiLz4KICAgIDwvcGF0dGVybj4KICA8L2RlZnM+CiAgPHJlY3Qgd2lkdGg9IjEwMCIgaGVpZ2h0PSIxMDAiIGZpbGw9InVybCgjdHJhbnN5bHZhbmlhbikiLz4KPC9zdmc+`,
            
            wallachianPattern: `data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz4KICAgIDxwYXR0ZXJuIGlkPSJ3YWxsYWNoaWFuIiBwYXR0ZXJuVW5pdHM9InVzZXJTcGFjZU9uVXNlIiB3aWR0aD0iMTYiIGhlaWdodD0iMTYiPgogICAgICA8cmVjdCB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIGZpbGw9IiMxYjVlMjAiLz4KICAgICAgPGxpbmUgeDE9IjAiIHkxPSI4IiB4Mj0iMTYiIHkyPSI4IiBzdHJva2U9IiNmZmQ3MDAiIHN0cm9rZS13aWR0aD0iMiIvPgogICAgICA8bGluZSB4MT0iOCIgeTE9IjAiIHgyPSI4IiB5Mj0iMTYiIHN0cm9rZT0iI2ZmZDcwMCIgc3Ryb2tlLXdpZHRoPSIyIi8+CiAgICA8L3BhdHRlcm4+CiAgPC9kZWZzPgogIDxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJ1cmwoI3dhbGxhY2hpYW4pIi8+Cjwvc3ZnPg==`
        };
    }
    
    /**
     * Create premium physical-based card material
     */
    createPremiumCardMaterial(cardType = 'playing', region = 'moldovan') {
        const cacheKey = `${cardType}-${region}`;
        
        if (this.materialCache.has(cacheKey)) {
            return this.materialCache.get(cacheKey);
        }
        
        // Base physical properties for realistic card rendering
        const material = new THREE.MeshPhysicalMaterial({
            // Physical properties for authentic card feel
            roughness: 0.1,          // Smooth card surface
            metalness: 0.0,          // Non-metallic paper
            clearcoat: 0.3,          // Subtle protective coating
            clearcoatRoughness: 0.25, // Slight texture on coating
            
            // Color and appearance
            color: this.getCardBaseColor(cardType),
            opacity: 1.0,
            transparent: false,
            
            // Advanced lighting response
            reflectivity: 0.1,
            ior: 1.4, // Index of refraction similar to paper
            
            // Enable shadows and lighting
            shadowSide: THREE.DoubleSide,
            side: THREE.DoubleSide
        });
        
        // Apply Romanian cultural textures
        this.applyRomanianTextures(material, region);
        
        // Cache for performance
        this.materialCache.set(cacheKey, material);
        
        console.log(`🎨 Created premium ${cardType} material with ${region} cultural elements`);
        return material;
    }
    
    /**
     * Get base color for different card types
     */
    getCardBaseColor(cardType) {
        switch (cardType) {
            case 'playing':
                return this.romanianColors.cardWhite;
            case 'table':
                return this.romanianColors.forestGreen;
            case 'premium':
                return this.romanianColors.cardCream;
            default:
                return this.romanianColors.cardWhite;
        }
    }
    
    /**
     * Apply Romanian cultural textures to material
     */
    applyRomanianTextures(material, region) {
        // Load normal map for card texture
        const normalTexture = this.createCardNormalMap();
        material.normalMap = normalTexture;
        material.normalScale = new THREE.Vector2(0.3, 0.3);
        
        // Apply regional pattern as bump map
        const bumpTexture = this.createRomanianPatternTexture(region);
        material.bumpMap = bumpTexture;
        material.bumpScale = 0.05;
        
        // Add subtle roughness variation
        const roughnessTexture = this.createRoughnessMap();
        material.roughnessMap = roughnessTexture;
    }
    
    /**
     * Create card normal map for realistic surface detail
     */
    createCardNormalMap() {
        const size = 256;
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        
        // Create subtle paper fiber texture
        const imageData = ctx.createImageData(size, size);
        const data = imageData.data;
        
        for (let i = 0; i < data.length; i += 4) {
            // Subtle normal map for paper texture
            const noise = (Math.random() - 0.5) * 0.1;
            data[i] = 128 + noise * 255;     // R: Normal X
            data[i + 1] = 128 + noise * 255; // G: Normal Y  
            data[i + 2] = 255;               // B: Normal Z (pointing up)
            data[i + 3] = 255;               // A: Alpha
        }
        
        ctx.putImageData(imageData, 0, 0);
        
        const texture = new THREE.CanvasTexture(canvas);
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.repeat.set(2, 2);
        
        return texture;
    }
    
    /**
     * Create Romanian cultural pattern texture
     */
    createRomanianPatternTexture(region) {
        const patternSvg = this.culturalPatterns[region + 'Border'] || this.culturalPatterns.moldovanBorder;
        
        // Convert SVG to texture
        const img = new Image();
        img.src = patternSvg;
        
        const texture = new THREE.Texture(img);
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.repeat.set(4, 4); // Tile the pattern
        
        img.onload = () => {
            texture.needsUpdate = true;
        };
        
        return texture;
    }
    
    /**
     * Create roughness map for material variation
     */
    createRoughnessMap() {
        const size = 128;
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        
        // Create subtle roughness variation
        const gradient = ctx.createRadialGradient(
            size/2, size/2, 0,
            size/2, size/2, size/2
        );
        gradient.addColorStop(0, 'rgb(100, 100, 100)'); // Smoother center
        gradient.addColorStop(1, 'rgb(140, 140, 140)'); // Rougher edges
        
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, size, size);
        
        const texture = new THREE.CanvasTexture(canvas);
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        
        return texture;
    }
    
    /**
     * Create material for Romanian game table surface
     */
    createTableMaterial(region = 'traditional') {
        const material = new THREE.MeshPhysicalMaterial({
            color: this.romanianColors.forestGreen,
            roughness: 0.8,  // Felt texture
            metalness: 0.0,
            
            // Table-specific properties
            opacity: 1.0,
            transparent: false,
            side: THREE.DoubleSide
        });
        
        // Add felt texture
        const feltTexture = this.createFeltTexture();
        material.map = feltTexture;
        material.normalMap = feltTexture;
        material.normalScale = new THREE.Vector2(0.5, 0.5);
        
        // Add Romanian border pattern
        const borderPattern = this.createRomanianPatternTexture(region);
        material.alphaMap = borderPattern;
        
        console.log(`🎨 Created premium table material with ${region} cultural elements`);
        return material;
    }
    
    /**
     * Create felt texture for game table
     */
    createFeltTexture() {
        const size = 512;
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        
        // Base felt color
        ctx.fillStyle = '#1b5e20';
        ctx.fillRect(0, 0, size, size);
        
        // Add felt fiber texture
        const imageData = ctx.getImageData(0, 0, size, size);
        const data = imageData.data;
        
        for (let i = 0; i < data.length; i += 4) {
            const noise = (Math.random() - 0.5) * 30;
            data[i] = Math.max(0, Math.min(255, data[i] + noise));     // R
            data[i + 1] = Math.max(0, Math.min(255, data[i + 1] + noise)); // G
            data[i + 2] = Math.max(0, Math.min(255, data[i + 2] + noise)); // B
        }
        
        ctx.putImageData(imageData, 0, 0);
        
        const texture = new THREE.CanvasTexture(canvas);
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.repeat.set(8, 8);
        
        return texture;
    }
    
    /**
     * Create material for card suit symbols with Romanian styling
     */
    createSuitMaterial(suit) {
        const suitColors = {
            'hearts': this.romanianColors.red,
            'diamonds': this.romanianColors.red,
            'clubs': this.romanianColors.shadowGray,
            'spades': this.romanianColors.shadowGray
        };
        
        const material = new THREE.MeshPhysicalMaterial({
            color: suitColors[suit] || this.romanianColors.shadowGray,
            roughness: 0.2,
            metalness: 0.0,
            opacity: 1.0,
            transparent: false
        });
        
        console.log(`🃏 Created ${suit} suit material with Romanian styling`);
        return material;
    }
    
    /**
     * Update materials for performance optimization
     */
    updateLOD(qualityLevel) {
        const materials = Array.from(this.materialCache.values());
        
        switch (qualityLevel) {
            case 'ultra':
                materials.forEach(material => {
                    material.clearcoat = 0.3;
                    material.normalScale.set(0.3, 0.3);
                    material.bumpScale = 0.05;
                });
                break;
                
            case 'high':
                materials.forEach(material => {
                    material.clearcoat = 0.2;
                    material.normalScale.set(0.2, 0.2);
                    material.bumpScale = 0.03;
                });
                break;
                
            case 'medium':
                materials.forEach(material => {
                    material.clearcoat = 0.1;
                    material.normalScale.set(0.1, 0.1);
                    material.bumpScale = 0.02;
                });
                break;
                
            case 'low':
                materials.forEach(material => {
                    material.clearcoat = 0.0;
                    material.normalScale.set(0.0, 0.0);
                    material.bumpScale = 0.0;
                });
                break;
        }
        
        console.log(`🎨 Materials updated for ${qualityLevel} quality level`);
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        // Dispose of all cached materials
        this.materialCache.forEach(material => material.dispose());
        this.materialCache.clear();
        
        // Dispose of all textures
        this.textures.forEach(texture => texture.dispose());
        this.textures.clear();
        
        console.log('🎨 Premium Card Material System disposed');
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PremiumCardMaterial;
} else if (typeof window !== 'undefined') {
    window.PremiumCardMaterial = PremiumCardMaterial;
}