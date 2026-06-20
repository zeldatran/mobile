package com.trannguyendiemhanh.auth.service;

import com.trannguyendiemhanh.auth.entity.Gallery;

import java.util.List;
import java.util.UUID;

public interface GalleryService extends CrudService<Gallery, UUID> {
    List<Gallery> getByProductId(UUID productId);
}
