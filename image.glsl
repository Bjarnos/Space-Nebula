// Space Nebula shader by Bjarnos
// I spent quite some time perfecting this so please like ( ˶ˆᗜˆ˵ )

// source: https://thebookofshaders.com/08/
mat2 spin(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// source: https://thebookofshaders.com/10/
float randomSeed(vec2 pos) {
    pos = fract(pos * vec2(123.34, 456.21));
    pos += dot(pos, pos + 45.32);
    return fract(pos.x * pos.y);
}

// source: https://thebookofshaders.com/11/
float blurryNoise(vec2 coords) {
    vec2 gridBox = floor(coords);
    vec2 subPixelOffset = fract(coords);
    
    vec2 smoothCurve = subPixelOffset * subPixelOffset * (3.0 - 2.0 * subPixelOffset);

    float cornerBottomLeft = randomSeed(gridBox);
    float cornerBottomRight = randomSeed(gridBox + vec2(1.0, 0.0));
    float cornerTopLeft = randomSeed(gridBox + vec2(0.0, 1.0));
    float cornerTopRight = randomSeed(gridBox + vec2(1.0, 1.0));

    return mix(
        mix(cornerBottomLeft, cornerBottomRight, smoothCurve.x), 
        mix(cornerTopLeft, cornerTopRight, smoothCurve.x), 
        smoothCurve.y
    );
}

// source: https://thebookofshaders.com/13/
float cloud(vec2 spot) {
    float total = 0.0;
    float opacityMultiplier = 0.5;
    mat2 rotater = spin(0.37);

    for (int loopCount = 0; loopCount < 6; loopCount++) {
        total += opacityMultiplier * blurryNoise(spot);
        spot = rotater * spot * 2.05 + vec2(0.5, 0.2);
        opacityMultiplier *= 0.52;
    }
    return total;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 screenPos = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float slowTime = iTime * 0.04;

    // source: https://thebookofshaders.com/13/ (domain warping)
    vec2 smallSwirl = vec2(
        cloud(screenPos * 1.5 + vec2(0.0, slowTime * 0.4)),
        cloud(screenPos * 1.5 + vec2(3.1, -slowTime * 0.3))
    );

    vec2 bigSwirl = vec2(
        cloud(screenPos * 2.2 + 2.5 * smallSwirl + vec2(1.4, 2.8 + slowTime * 0.2)),
        cloud(screenPos * 2.2 + 2.5 * smallSwirl + vec2(5.2, 1.1 - slowTime * 0.2))
    );

    float fogAmount = cloud(screenPos * 1.8 + 2.0 * bigSwirl);
    float thickFog = smoothstep(0.2, 0.9, fogAmount);

    vec3 black = vec3(0.02, 0.03, 0.08);
    vec3 pink = vec3(0.85, 0.12, 0.42);
    vec3 cyan = vec3(0.05, 0.75, 0.92);
    vec3 blue = vec3(0.12, 0.28, 0.85);
    vec3 white = vec3(0.95, 0.98, 1.0);

    float distFromMiddle = length(screenPos - vec2(0.05, 0.02));
    float middleGlowBall = exp(-distFromMiddle * 2.2);

    vec3 finalPixelColor = black;
    finalPixelColor += blue * smoothstep(0.1, 0.7, fogAmount) * 0.9;
    finalPixelColor = mix(finalPixelColor, cyan, smoothstep(0.35, 0.75, bigSwirl.x) * 1.1);
    finalPixelColor = mix(finalPixelColor, pink, smoothstep(0.3, 0.8, bigSwirl.y) * 1.2);
    
    finalPixelColor += white * pow(thickFog, 2.5) * middleGlowBall * 1.6;
    finalPixelColor += cyan * middleGlowBall * 0.5;

    float dirtyDust = cloud(screenPos * 3.0 + smallSwirl * 1.5);
    float blackSmokeLayer = smoothstep(0.45, 0.75, dirtyDust);
    finalPixelColor = mix(finalPixelColor, black * 0.6, blackSmokeLayer * 0.75);

    // mini stars (need to improve these)
    vec2 starTileGrid = fragCoord * 0.35;
    float starRandomChance = randomSeed(floor(starTileGrid));
    if (starRandomChance > 0.986) {
        float starDot = smoothstep(0.35, 0.0, length(fract(starTileGrid) - 0.5));
        finalPixelColor += vec3(0.7, 0.85, 1.0) * starDot * (0.4 + 0.6 * starRandomChance);
    }

    // big star
    vec2 bigStarCoords = screenPos - vec2(0.08, 0.04);
    float starDistance = length(bigStarCoords);
    float shinyGlare = 0.008 / (starDistance + 0.003);
    finalPixelColor += vec3(0.9, 0.95, 1.0) * shinyGlare;

    finalPixelColor = (finalPixelColor * (2.51 * finalPixelColor + 0.03)) / (finalPixelColor * (2.43 * finalPixelColor + 0.59) + 0.14);

    fragColor = vec4(finalPixelColor, 1.0);
}