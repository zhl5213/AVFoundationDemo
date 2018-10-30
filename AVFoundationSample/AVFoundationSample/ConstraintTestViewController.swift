//
//  ConstraintTestViewController.swift
//  AVFoundationSample
//
//  Created by 朱慧林 on 2018/10/22.
//  Copyright © 2018年 朱慧林. All rights reserved.
//

import UIKit
import OpenGLES
import GLKit

class ConstraintTestViewController: UIViewController {
    
 
}


class EAGLView: UIView {
    
    var renderBuffer:GLuint = 0
    var frameBuffer:GLuint = 0
    var glContext:EAGLContext?
    var glLayer:CAEAGLLayer?

    override class var layerClass:AnyClass {
        return CAEAGLLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        let glContext = EAGLContext.init(api: EAGLRenderingAPI.openGLES3)
        EAGLContext.setCurrent(glContext)
        self.glContext = glContext
        
        glLayer = layer as? CAEAGLLayer
        glLayer?.isOpaque = true
        glLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking:false,kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
 
        destoryRenderAndFrameBuffer()
        setRenderBuffer()
        setupFrameBuffer()
        renderBGColor()
        
    }
    
    func setRenderBuffer() -> () {
        glGenBuffers(1, &renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        glContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: glLayer)
    }
    
    func setupFrameBuffer() -> () {
        glGenBuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
    }
    
    func destoryRenderAndFrameBuffer() -> () {
        glDeleteBuffers(1, &renderBuffer)
        renderBuffer = 0
        glDeleteBuffers(1, &frameBuffer)
        frameBuffer = 0
    }
    
    func renderBGColor() -> () {
        glClearColor(0, 1, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glContext?.presentRenderbuffer(Int(renderBuffer))
    }
    
}
