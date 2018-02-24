//
//  ViewController.swift
//  ShaderViewController
//
//  Created by rhinoid on 02/11/2018.
//  Copyright (c) 2018 rhinoid. All rights reserved.
//

import UIKit
import Pods_ShaderViewController_Example


class ViewController: ShaderVC {
    
    let shader = """
    //
    //  RotateShader.fsh
    //  shaderTest
    //
    //  Created by Reinier van Vliet on 01/02/18.
    //

    precision highp float;

    uniform vec2 u_resolution;
    uniform float u_time;

    void main()
    {
        vec2 px = gl_FragCoord.xy/u_resolution.xy;
        
        vec2 center = vec2(0.5, 0.5);
        float dist = distance(px, center) / 2.0;
        vec2 up = vec2(0.0,1.0);
        vec2 centerVec = normalize(px - center);
        float angle = acos(dot(up, centerVec)) / 3.14159265359;
        angle *= 4.0;
        if (px.x >= 0.5) {
            angle = 1.0-angle;
        }
        angle += sin(u_time) * dist * 2.0;
        angle += u_time/2.0;
        angle = fract(angle);
        
        float r = step(0.5, angle);
        
        vec4 color1 = vec4(0.05,0.6,0.8,1.0) * r;
        vec4 color2 = vec4(0.05,0.8,1.0,1.0) * (1.0-r);
        vec4 backColor = vec4(0.05, 0.6, 0.8, 1.0);
        vec4 rotateColor = color1 + color2;
        gl_FragColor = mix(backColor, rotateColor, dist);
    }
    """

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configure(shaderCode: shader)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

