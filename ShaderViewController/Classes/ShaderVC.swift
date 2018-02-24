//
//  ShaderVC.swift
//  deleteme
//
//  Created by reinier van vliet on 01/02/18.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

open class ShaderVC: GLKViewController {
    
    // Constants
    private let UNIFORM_MODELVIEWPROJECTION_MATRIX = 0
    private let UNIFORM_NORMAL_MATRIX = 1
    private var uniforms = [GLint](repeating: 0, count: 2)
    
    // Vertex shader
    private let shaderVsh = """
attribute vec4 position;
attribute vec3 normal;
uniform mat4 modelViewProjectionMatrix;
void main()
{
    gl_Position = modelViewProjectionMatrix * position;
}
"""
    
    /// vertex data
    var gSquareVertexData: [GLfloat] = [
        // Data layout for each line below is:
        // positionX, positionY, positionZ,     normalX, normalY, normalZ,
        -1.0, -1.0, 0.0,        0.0, 0.0, 1.0,
        1.0, -1.0, 0.0,         0.0, 0.0, 1.0,
        -1.0,  1.0, 0.0,         0.0, 0.0, 1.0,
        1.0,  1.0, 0.0,        0.0, 0.0, 1.0,
        -1.0,  1.0, 0.0,         0.0, 0.0, 1.0,
        1.0, -1.0, 0.0,         0.0, 0.0, 1.0
    ]

    // Fragment shader
    private var shaderCode: String = ""

    // Shader program
    private var program: GLuint = 0

    // Projection matrix
    private var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    
    // Triangle data
    private var vertexArray: GLuint = 0
    private var vertexBuffer: GLuint = 0
    
    private var context: EAGLContext? = nil

    // To measure time elapsed
    private var startTime: CFTimeInterval = 0
    
    deinit {
        self.tearDownGL()
        
        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    // Load, compile and run the shader code into the view
    open func configure(shaderCode: String) {
        self.shaderCode = shaderCode
    }
    
    // Restart the shader animation
    open func restartShader() {
        _ = loadShaders()
    }
    
    // MARK: View lifetime
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        context = EAGLContext(api: .openGLES2)
        
        preferredFramesPerSecond = 60
        
        if !(context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupGL()
        startTime = CACurrentMediaTime();
    }
    
    // MARK: setup and teardown opengl
    
    private func setupGL() {
        EAGLContext.setCurrent(self.context)
        
        _ = self.loadShaders()
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * gSquareVertexData.count), &gSquareVertexData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(12))
        
        glBindVertexArrayOES(0)
    }
    
    private func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }
    }
    
    private func tearDownView() {
        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }

    // MARK: - GLKView and GLKViewController delegate methods
    
    open override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        let currentTime = CACurrentMediaTime()
        
        //clear buffers
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        //prepare pipeline
        glBindVertexArrayOES(vertexArray)
        glUseProgram(program)
        
        //pass constants to shader
        let screenScale = UIScreen.main.scale
        let myUniformResolutionLocation: GLint = glGetUniformLocation(program, "u_resolution");
        glUniform2f(myUniformResolutionLocation, Float(view.frame.size.width) * Float(screenScale), Float(view.frame.size.height) * Float(screenScale))
        
        let timePassed: GLfloat = GLfloat(currentTime - startTime)
        let myUniformLocationTime: GLint = glGetUniformLocation(program, "u_time");
        glUniform1f(myUniformLocationTime, timePassed)
        
        withUnsafePointer(to: &modelViewProjectionMatrix) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: 1) {matrix in
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, matrix)
            }
        }
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
    }
    
    private func update() {
        let baseModelViewMatrix = GLKMatrix4Identity
        modelViewProjectionMatrix = baseModelViewMatrix
    }
    
    
    // MARK: -  OpenGL ES 2 shader compilation
    
    private func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        
        // Create shader program.
        program = glCreateProgram()

        // Create and compile vertex shader.
        if self.compileShader(shader: &vertShader, type: GLenum(GL_VERTEX_SHADER), code: shaderVsh) == false {
            print("Failed to compile vertex shader")
            return false
        }
        
        // Compile fragment shader
        if !self.compileShader(shader: &fragShader, type: GLenum(GL_FRAGMENT_SHADER), code: shaderCode) {
            print("Failed to compile fragment shader")
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.position.rawValue), "position")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.normal.rawValue), "normal")
        
        // Link program.
        if !linkProgram(prog: program) {
            print("Failed to link program: \(program)")
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            
            return false
        }
        
        // Get uniform locations.
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix")
        uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(program, "normalMatrix")
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        return true
    }
    
    
    private func compileShader( shader: inout GLuint, type: GLenum, code: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        source = (code as NSString).utf8String!
        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
        
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        
        var logLength: GLint = 0
        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var infoLog = [GLchar](repeating: 0, count: 512)
            glGetShaderInfoLog(shader, 512, nil, &infoLog)
            let errors = String(validatingUTF8: infoLog)
            print("Shader compile log: \(errors ?? "")")
        }
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    private func linkProgram(prog: GLuint) -> Bool {
        var status: GLint = 0
        glLinkProgram(prog)
        
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            var logLength: GLsizei = 0
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            let errors = String(validatingUTF8: log)
            print("Shader link log: \(errors ?? "")")
            return false
        }
        
        return true
    }
    
    private func validateProgram(prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
}
