package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.VariantOption;
import com.trannguyendiemhanh.auth.repository.VariantOptionRepository;
import com.trannguyendiemhanh.auth.service.VariantOptionService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class VariantOptionServiceImpl extends JpaCrudServiceImpl<VariantOption, UUID> implements VariantOptionService {
    public VariantOptionServiceImpl(VariantOptionRepository repository) {
        super(repository);
    }
}
