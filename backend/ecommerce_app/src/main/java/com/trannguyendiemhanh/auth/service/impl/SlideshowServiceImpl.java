package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Slideshow;
import com.trannguyendiemhanh.auth.repository.SlideshowRepository;
import com.trannguyendiemhanh.auth.service.SlideshowService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class SlideshowServiceImpl extends JpaCrudServiceImpl<Slideshow, UUID> implements SlideshowService {
    public SlideshowServiceImpl(SlideshowRepository repository) {
        super(repository);
    }
}
