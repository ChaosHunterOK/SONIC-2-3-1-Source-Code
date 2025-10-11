local ffi = pcall(require, "ffi") and require("ffi") or nil
local osname = love.system.getOS()
local gl = nil

if ffi then
    ffi.cdef[[
        typedef unsigned int GLenum;
        typedef unsigned char GLboolean;
        typedef unsigned int GLbitfield;
        typedef void GLvoid;
        typedef int GLint;
        typedef unsigned int GLuint;
        typedef int GLsizei;
        typedef float GLfloat;

        void glEnable(GLenum cap);
        void glDisable(GLenum cap);
        void glHint(GLenum target, GLenum mode);
        void glDepthMask(GLboolean flag);
        void glDepthFunc(GLenum func);
        void glBlendFunc(GLenum sfactor, GLenum dfactor);
    ]]

    if osname == "Windows" then
        gl = ffi.load("opengl32")
    elseif osname == "OS X" or osname == "macOS" then
        gl = ffi.load("/System/Library/Frameworks/OpenGL.framework/OpenGL")
    elseif osname == "Linux" then
        gl = ffi.load("GL")
    else
        gl = nil
    end
end

local GL_DEPTH_TEST = 0x0B71
local GL_CULL_FACE = 0x0B44
local GL_BLEND = 0x0BE2
local GL_LEQUAL = 0x0203
local GL_SRC_ALPHA = 0x0302
local GL_ONE_MINUS_SRC_ALPHA = 0x0303
local GL_FASTEST = 0x1101

local function initGL()
    if gl then
        gl.glEnable(GL_DEPTH_TEST)
        gl.glDepthFunc(GL_LEQUAL)
        gl.glDepthMask(true)
        gl.glEnable(GL_CULL_FACE)
        gl.glEnable(GL_BLEND)
        gl.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        gl.glHint(0x0C50, GL_FASTEST)
        gl.glHint(0x0C51, GL_FASTEST)
        gl.glHint(0x0C52, GL_FASTEST)
        gl.glHint(0x0C53, GL_FASTEST)
        gl.glHint(0x0C54, GL_FASTEST)
    else
        love.graphics.setDepthMode("lequal", true)
        --love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setDefaultFilter("nearest", "nearest")
    end

    love.window.setMode(0, 0, {
        vsync = 1,
        msaa = 0,
        depth = 24,
        stencil = true,
        resizable = false,
        highdpi = osname == "OS X" or osname == "macOS",
    })

    collectgarbage("setpause", 110)
    collectgarbage("setstepmul", 200)

    print(string.format("[OpenGL] Performance optimization active (%s)", osname))
end

return {
    init = initGL
}