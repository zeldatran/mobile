package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Gallery;
import com.trannguyendiemhanh.auth.service.GalleryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/gallery")
public class GalleryController extends CrudController<Gallery, UUID> {
    private final GalleryService galleryService;

    public GalleryController(GalleryService service) {
        super(service);
        this.galleryService = service;
    }

    @GetMapping("/product/{productId}")
    public ResponseEntity<List<Gallery>> getByProductId(@PathVariable UUID productId) {
        return ResponseEntity.ok(galleryService.getByProductId(productId));
    }
}
