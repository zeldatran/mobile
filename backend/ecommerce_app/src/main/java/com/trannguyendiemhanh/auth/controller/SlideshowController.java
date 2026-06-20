package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Slideshow;
import com.trannguyendiemhanh.auth.service.SlideshowService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/slideshows")
public class SlideshowController extends CrudController<Slideshow, UUID> {
    public SlideshowController(SlideshowService service) {
        super(service);
    }
}
