from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.contrib.auth import update_session_auth_hash
from .models import UserProfile
from .serializers import (
    UserRegistrationSerializer, 
    UserLoginSerializer, 
    UserSerializer, 
    UserProfileSerializer,
    PasswordChangeSerializer
)


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """
    User registration endpoint
    """
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        
        return Response({
            'message': 'User registered successfully',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(access_token),
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    User login endpoint
    """
    serializer = UserLoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        
        return Response({
            'message': 'Login successful',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(access_token),
            }
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    User logout endpoint - blacklist refresh token
    """
    try:
        refresh_token = request.data.get('refresh_token')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
        return Response({'message': 'Successfully logged out'})
    except Exception as e:
        return Response({'error': 'Invalid token'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile(request):
    """
    Get current user profile
    """
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Update user profile
    """
    user = request.user
    user_data = {
        'username': request.data.get('username', user.username),
        'email': request.data.get('email', user.email),
        'first_name': request.data.get('first_name', user.first_name),
        'last_name': request.data.get('last_name', user.last_name),
    }
    
    # Update user basic info
    user_serializer = UserSerializer(user, data=user_data, partial=True)
    if user_serializer.is_valid():
        user_serializer.save()
        
        # Update profile
        profile_serializer = UserProfileSerializer(
            user.profile, 
            data=request.data, 
            partial=True
        )
        if profile_serializer.is_valid():
            profile_serializer.save()
            return Response({
                'message': 'Profile updated successfully',
                'user': UserSerializer(user).data
            })
        else:
            return Response(profile_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(user_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Change user password
    """
    serializer = PasswordChangeSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        # Update session to prevent logout
        update_session_auth_hash(request, user)
        
        return Response({'message': 'Password changed successfully'})
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_account(request):
    """
    Delete user account
    """
    user = request.user
    user.delete()
    return Response({'message': 'Account deleted successfully'})


class UserListView(generics.ListAPIView):
    """
    List all users (admin only)
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_stats(request):
    """
    Get user statistics
    """
    user = request.user
    from detector.models import Detection
    
    detections = Detection.objects.filter(user=user)
    total_detections = detections.count()
    
    if total_detections > 0:
        avg_confidence = sum(d.confidence_avg for d in detections) / total_detections
        avg_processing_time = sum(d.processing_time for d in detections) / total_detections
        total_signs_detected = sum(d.detections_count for d in detections)
    else:
        avg_confidence = 0
        avg_processing_time = 0
        total_signs_detected = 0
    
    return Response({
        'total_sessions': total_detections,
        'total_signs_detected': total_signs_detected,
        'avg_confidence': round(avg_confidence, 3),
        'avg_processing_time': round(avg_processing_time, 3),
        'member_since': user.date_joined,
    }) 