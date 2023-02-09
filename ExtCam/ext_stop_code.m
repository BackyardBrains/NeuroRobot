
if flag
    close(fig1)
    if strcmp(cam.Running, 'off')
        stop(cam)
    end
    delete(timerfind)
end