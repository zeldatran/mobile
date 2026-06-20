package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Gallery;
import com.trannguyendiemhanh.auth.repository.GalleryRepository;
import com.trannguyendiemhanh.auth.service.GalleryService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class GalleryServiceImpl extends JpaCrudServiceImpl<Gallery, UUID> implements GalleryService {
    private final GalleryRepository galleryRepository;

    public GalleryServiceImpl(GalleryRepository repository) {
        super(repository);
        this.galleryRepository = repository;
    }

    @Override
    public List<Gallery> getByProductId(UUID productId) {
        return galleryRepository.findByProductId(productId);
    }
}
